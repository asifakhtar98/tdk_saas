import { Page, expect } from '@playwright/test';

/**
 * Helper utilities for testing Flutter Web applications with Playwright.
 *
 * Flutter Web (CanvasKit) renders into a `<canvas>` element, so standard
 * DOM selectors cannot interact with Flutter widget content directly.
 * Instead, we rely on Flutter's **accessibility semantics tree**, which
 * generates `<flt-semantics>` DOM elements with ARIA roles and labels.
 *
 * The TKD Brackets app calls `WidgetsFlutterBinding.ensureSemantics()` on
 * web, so the semantics tree is always present without needing to click
 * the "Enable accessibility" button.
 *
 * Strategy:
 * 1. For the static HTML landing page → use standard DOM selectors.
 * 2. For Flutter-rendered content → use ARIA/role-based locators on
 *    the semantics tree elements.
 */

/**
 * Maximum time to wait for the Flutter app to fully initialize.
 * Flutter Web WASM/JS compilation can take significant time.
 */
const FLUTTER_LOAD_TIMEOUT = 45_000;

/**
 * Time to wait for Flutter route transitions to settle.
 */
const ROUTE_SETTLE_TIME = 3_000;

/**
 * Time to wait for semantics tree to be populated after Flutter loads.
 */
const SEMANTICS_SETTLE_TIME = 2_000;

/**
 * Waits for the static landing page to be fully loaded and visible.
 */
export async function waitForLandingPage(page: Page): Promise<void> {
    await page.waitForSelector('#landing-container', {
        state: 'visible',
        timeout: 15_000,
    });
    await page.waitForSelector('#hero-cta-btn', {
        state: 'visible',
        timeout: 10_000,
    });
}

/**
 * Clicks the CTA button on the landing page to launch the Flutter app.
 * Waits for the loading overlay to appear, then for Flutter to initialize
 * and the semantics tree to be populated.
 */
export async function launchFlutterApp(page: Page): Promise<void> {
    await page.click('#hero-cta-btn');

    // Wait for loading overlay
    await page.waitForSelector('#flutter-loading.active', {
        state: 'visible',
        timeout: 5_000,
    });

    // Wait for Flutter to bootstrap
    await page.waitForFunction(
        () => document.body.classList.contains('flutter-loaded'),
        { timeout: FLUTTER_LOAD_TIMEOUT },
    );

    // Wait for semantics tree to populate
    await page.waitForTimeout(ROUTE_SETTLE_TIME + SEMANTICS_SETTLE_TIME);
}

/**
 * Waits for the Flutter app to be ready when navigating directly
 * (e.g., via hash route or ?launch=true).
 */
export async function waitForFlutterReady(page: Page): Promise<void> {
    await page.waitForFunction(
        () => document.body.classList.contains('flutter-loaded'),
        { timeout: FLUTTER_LOAD_TIMEOUT },
    );
    await page.waitForTimeout(ROUTE_SETTLE_TIME + SEMANTICS_SETTLE_TIME);
}

/**
 * Checks if specific text exists in the Flutter semantics tree.
 * Now that semantics are always enabled, we check flt-semantics elements.
 */
export async function findFlutterText(
    page: Page,
    text: string,
    timeout = 10_000,
): Promise<boolean> {
    const startTime = Date.now();

    while (Date.now() - startTime < timeout) {
        // Check flt-semantics elements for aria-labels and text content
        const found = await page.evaluate((searchText) => {
            // Strategy 1: Check flt-semantics aria-labels
            const semantics = document.querySelectorAll('flt-semantics');
            for (const s of Array.from(semantics)) {
                const label = s.getAttribute('aria-label');
                if (label && label.includes(searchText)) return true;
                // Check text content of the element
                const content = (s as HTMLElement).innerText || s.textContent || '';
                if (content.includes(searchText)) return true;
            }

            // Strategy 2: Check any element with matching aria-label
            const labeled = document.querySelectorAll(`[aria-label*="${searchText}"]`);
            if (labeled.length > 0) return true;

            // Strategy 3: Check role="heading" elements
            const headings = document.querySelectorAll('[role="heading"]');
            for (const h of Array.from(headings)) {
                const label = h.getAttribute('aria-label');
                if (label && label.includes(searchText)) return true;
            }

            return false;
        }, text);

        if (found) return true;
        await page.waitForTimeout(500);
    }

    return false;
}

/**
 * Clicks a Flutter button by its text label using the semantics tree.
 */
export async function clickFlutterButton(
    page: Page,
    buttonText: string,
    timeout = 10_000,
): Promise<void> {
    // Try role-based locator (most reliable for Flutter semantics)
    const button = page.getByRole('button', { name: buttonText });

    try {
        await button.waitFor({ state: 'visible', timeout });
        await button.click();
    } catch {
        // Fallback: find by aria-label
        const ariaButton = page.locator(
            `flt-semantics[aria-label*="${buttonText}"][role="button"]`,
        );
        const count = await ariaButton.count();

        if (count > 0) {
            await ariaButton.first().click();
        } else {
            // Final fallback: try clicking by text content
            const textLocator = page.getByText(buttonText);
            await textLocator.waitFor({ state: 'visible', timeout: 5000 });
            await textLocator.click();
        }
    }

    // Allow route transition and re-render
    await page.waitForTimeout(ROUTE_SETTLE_TIME);
}

/**
 * Waits for a Flutter page to load by checking for expected text
 * in the semantics tree.
 */
export async function waitForFlutterPage(
    page: Page,
    expectedText: string,
    timeout = 15_000,
): Promise<void> {
    const found = await findFlutterText(page, expectedText, timeout);
    if (!found) {
        throw new Error(
            `Timed out waiting for Flutter page containing "${expectedText}" after ${timeout}ms`,
        );
    }
}

/**
 * Checks if the current URL hash matches expected route.
 * Flutter Web uses hash-based routing.
 */
export async function expectRoute(
    page: Page,
    expectedPath: string,
): Promise<void> {
    await page.waitForTimeout(1_000);
    const url = page.url();
    const pathMatch = new URL(url).pathname === expectedPath;

    expect(
        pathMatch,
        `Expected route "${expectedPath}" but got URL: ${url}`,
    ).toBeTruthy();
}

/**
 * Navigates directly to a Flutter route via hash.
 */
export async function navigateToRoute(
    page: Page,
    route: string,
): Promise<void> {
    await page.goto(route);
    await page.waitForTimeout(ROUTE_SETTLE_TIME + SEMANTICS_SETTLE_TIME);
}
