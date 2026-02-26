import { test, expect } from '@playwright/test';
import {
    waitForLandingPage,
    launchFlutterApp,
} from '../helpers/flutter-web.helpers';

/**
 * Test Suite 1: Landing Page (Static HTML)
 *
 * Tests the static HTML landing page that loads BEFORE the Flutter app.
 * This is the first thing a new user sees when visiting the website.
 *
 * Flow: User opens website → sees landing page → clicks CTA → Flutter loads
 */
test.describe('Landing Page - New User First Visit', () => {
    test.beforeEach(async ({ page }) => {
        // Navigate to the root URL (landing page)
        await page.goto('/');
    });

    test('LP-01: should display the landing page with correct branding', async ({
        page,
    }) => {
        await waitForLandingPage(page);

        // Verify landing container is visible
        const landingContainer = page.locator('#landing-container');
        await expect(landingContainer).toBeVisible();

        // Verify logo and brand name
        const logo = page.locator('.logo');
        await expect(logo).toBeVisible();
        await expect(logo).toContainText('TKD Brackets');

        // Verify the martial arts emoji icon
        const logoIcon = page.locator('.logo-icon');
        await expect(logoIcon).toBeVisible();
        await expect(logoIcon).toContainText('🥋');
    });

    test('LP-02: should display hero section with correct content', async ({
        page,
    }) => {
        await waitForLandingPage(page);

        // Verify hero badge
        const heroBadge = page.locator('.hero-badge');
        await expect(heroBadge).toBeVisible();
        await expect(heroBadge).toContainText('Built for Taekwondo');

        // Verify hero title
        const heroTitle = page.locator('.hero-title');
        await expect(heroTitle).toBeVisible();
        await expect(heroTitle).toContainText('Create Tournament Brackets in');
        await expect(heroTitle).toContainText('Minutes, Not Hours');

        // Verify hero subtitle mentions key features
        const heroSubtitle = page.locator('.hero-subtitle');
        await expect(heroSubtitle).toBeVisible();
        await expect(heroSubtitle).toContainText('Smart Division Builder');
        await expect(heroSubtitle).toContainText('Dojang separation seeding');
    });

    test('LP-03: should display CTA button', async ({ page }) => {
        await waitForLandingPage(page);

        const ctaButton = page.locator('#hero-cta-btn');
        await expect(ctaButton).toBeVisible();
        await expect(ctaButton).toContainText("Get Started — It's Free");
        await expect(ctaButton).toBeEnabled();
    });

    test('LP-04: should display bracket mockup preview', async ({ page }) => {
        await waitForLandingPage(page);

        // Verify bracket preview card
        const bracketPreview = page.locator('.bracket-preview');
        await expect(bracketPreview).toBeVisible();

        // Verify bracket header
        const bracketTitle = page.locator('.bracket-title');
        await expect(bracketTitle).toContainText('Juniors -45kg Sparring');

        // Verify "Live" badge in bracket preview
        const bracketBadge = page.locator('.bracket-badge');
        await expect(bracketBadge).toContainText('Live');

        // Verify match players are displayed
        const matchPlayers = page.locator('.match-player');
        expect(await matchPlayers.count()).toBeGreaterThanOrEqual(4);
    });

    test('LP-05: should have correct SEO meta tags', async ({ page }) => {
        // Check title
        await expect(page).toHaveTitle(
            'TKD Brackets - Tournament Bracket Maker for Taekwondo',
        );

        // Check meta description
        const metaDesc = page.locator('meta[name="description"]');
        const content = await metaDesc.getAttribute('content');
        expect(content).toContain('tournament brackets');
        expect(content).toContain('Taekwondo');

        // Check Open Graph tags
        const ogTitle = page.locator('meta[property="og:title"]');
        await expect(ogTitle).toHaveAttribute(
            'content',
            'TKD Brackets - Tournament Bracket Maker for Taekwondo',
        );

        // Check structured data
        const structuredData = page.locator(
            'script[type="application/ld+json"]',
        );
        const jsonContent = await structuredData.textContent();
        expect(jsonContent).toContain('TKD Brackets');
        expect(jsonContent).toContain('SportsApplication');
    });

    test('LP-06: should show loading state when CTA is clicked', async ({
        page,
    }) => {
        await waitForLandingPage(page);

        // Loading overlay should be hidden initially
        const loadingOverlay = page.locator('#flutter-loading');
        await expect(loadingOverlay).not.toBeVisible();

        // Click CTA
        await page.click('#hero-cta-btn');

        // Loading overlay should become visible
        await expect(loadingOverlay).toBeVisible({ timeout: 5_000 });

        // Verify loading content
        const loadingText = page.locator('.loading-text');
        await expect(loadingText).toContainText('Loading TKD Brackets');

        // Verify spinner
        const spinner = page.locator('.loading-spinner');
        await expect(spinner).toBeVisible();
    });

    test('LP-07: should auto-launch Flutter with #app hash', async ({
        page,
    }) => {
        // Navigate with #app hash
        await page.goto('/#app');

        // Should show loading state automatically
        const loadingOverlay = page.locator('#flutter-loading.active');
        await expect(loadingOverlay).toBeVisible({ timeout: 10_000 });
    });

    test('LP-08: should auto-launch Flutter with launch=true param', async ({
        page,
    }) => {
        // Navigate with launch=true query param
        await page.goto('/?launch=true');

        // Should show loading state automatically
        const loadingOverlay = page.locator('#flutter-loading.active');
        await expect(loadingOverlay).toBeVisible({ timeout: 10_000 });
    });
});
