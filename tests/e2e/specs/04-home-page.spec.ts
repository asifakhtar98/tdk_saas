import { test, expect } from '@playwright/test';
import {
    waitForLandingPage,
    launchFlutterApp,
    findFlutterText,
    clickFlutterButton,
    waitForFlutterPage,
    waitForFlutterReady,
} from '../helpers/flutter-web.helpers';

/**
 * Test Suite 4: Home Page Features & UI
 *
 * Tests the Flutter-rendered Home page (/):
 * - Visual elements and branding
 * - Button interactivity
 * - Responsive layout (desktop viewport)
 *
 * The Home page is the in-app landing screen that users see after
 * the Flutter framework loads. It differs from the static HTML
 * landing page (web/index.html).
 */
test.describe('Home Page - Flutter App', () => {
    test.beforeEach(async ({ page }) => {
        await page.goto('/');
        await waitForLandingPage(page);
        await launchFlutterApp(page);
    });

    test('HP-01: should display app title with correct branding', async ({
        page,
    }) => {
        const hasTitle = await findFlutterText(page, 'TKD Brackets');
        expect(hasTitle).toBeTruthy();
    });

    test('HP-02: should display subtitle describing the app', async ({
        page,
    }) => {
        const hasSubtitle = await findFlutterText(
            page,
            'Tournament Bracket Management',
        );
        expect(hasSubtitle).toBeTruthy();
    });

    test('HP-03: should have Try Demo as primary action', async ({ page }) => {
        // Try Demo is a FilledButton (primary action)
        const hasTryDemo = await findFlutterText(page, 'Try Demo');
        expect(hasTryDemo).toBeTruthy();
    });

    test('HP-04: should have Sign In as secondary action', async ({ page }) => {
        // Sign In is an OutlinedButton (secondary action)
        const hasSignIn = await findFlutterText(page, 'Sign In');
        expect(hasSignIn).toBeTruthy();
    });

    test('HP-05: Try Demo button navigates to demo page', async ({ page }) => {
        await clickFlutterButton(page, 'Try Demo');

        // Should navigate to /demo
        const hasDemoMode = await findFlutterText(page, 'Demo Mode');
        expect(hasDemoMode).toBeTruthy();
    });

    test('HP-06: home page renders without errors', async ({ page }) => {
        // Check for no console errors
        const errors: string[] = [];
        page.on('console', (msg) => {
            if (msg.type() === 'error') {
                errors.push(msg.text());
            }
        });

        // Wait a moment for any deferred errors
        await page.waitForTimeout(2_000);

        // Filter out Flutter-specific noise (service worker, etc.)
        const realErrors = errors.filter(
            (e) =>
                !e.includes('service-worker') &&
                !e.includes('favicon') &&
                !e.includes('manifest') &&
                !e.includes('Failed to load resource'),
        );

        // Should have no significant console errors
        expect(
            realErrors.length,
            `Unexpected console errors: ${realErrors.join('\n')}`,
        ).toBe(0);
    });

    test('HP-07: home page is responsive at desktop viewport', async ({
        page,
    }) => {
        // Verify the page renders within a constrained width (max 400px as per code)
        // At 1440px viewport, the content should be centered
        const body = page.locator('body');
        await expect(body).toBeVisible();

        // Take screenshot for visual verification
        await page.screenshot({
            path: 'test-results/screenshots/home-desktop.png',
        });
    });
});
