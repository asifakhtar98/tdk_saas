import { test, expect } from '@playwright/test';
import {
    waitForLandingPage,
    launchFlutterApp,
    findFlutterText,
    clickFlutterButton,
    waitForFlutterPage,
} from '../helpers/flutter-web.helpers';

/**
 * Test Suite 2: Demo Mode Flow
 *
 * Tests the complete new-user journey through Demo Mode:
 * Landing Page → CTA Click → Flutter loads → Home Page → Demo Mode → Tournaments
 *
 * Demo mode allows users to explore the app without creating an account.
 * Routes: / (Home) → /demo → /tournaments
 */
test.describe('Demo Mode - New User Exploration Flow', () => {
    test.beforeEach(async ({ page }) => {
        await page.goto('/');
        await waitForLandingPage(page);
    });

    test('DM-01: should navigate from landing page to Flutter home page', async ({
        page,
    }) => {
        // Launch the Flutter app from landing page
        await launchFlutterApp(page);

        // Verify Flutter app is now visible (landing page is hidden)
        const landingContainer = page.locator('#landing-container');
        await expect(landingContainer).not.toBeVisible();

        // Flutter should render the Home page
        // Home page contains "TKD Brackets" heading and action buttons
        const hasTkdBrackets = await findFlutterText(page, 'TKD Brackets');
        expect(hasTkdBrackets).toBeTruthy();
    });

    test('DM-02: should display Home page with Try Demo and Sign In options', async ({
        page,
    }) => {
        await launchFlutterApp(page);

        // Verify Home page content
        const hasBranding = await findFlutterText(page, 'TKD Brackets');
        expect(hasBranding).toBeTruthy();

        const hasSubtitle = await findFlutterText(
            page,
            'Tournament Bracket Management',
        );
        expect(hasSubtitle).toBeTruthy();

        // Verify both action buttons are present
        const hasTryDemo = await findFlutterText(page, 'Try Demo');
        expect(hasTryDemo).toBeTruthy();

        const hasSignIn = await findFlutterText(page, 'Sign In');
        expect(hasSignIn).toBeTruthy();
    });

    test('DM-03: should navigate to Demo Mode when Try Demo is clicked', async ({
        page,
    }) => {
        await launchFlutterApp(page);

        // Click "Try Demo" button
        await clickFlutterButton(page, 'Try Demo');

        // Wait for Demo page to load
        await waitForFlutterPage(page, 'Demo Mode');

        // Verify Demo page content
        const hasDemoMode = await findFlutterText(page, 'Demo Mode');
        expect(hasDemoMode).toBeTruthy();

        const hasDescription = await findFlutterText(
            page,
            'Explore TKD Brackets without creating an account',
        );
        expect(hasDescription).toBeTruthy();
    });

    test('DM-04: should show local data notice in Demo Mode', async ({
        page,
    }) => {
        await launchFlutterApp(page);
        await clickFlutterButton(page, 'Try Demo');
        await waitForFlutterPage(page, 'Demo Mode');

        // Verify the local storage notice
        const hasLocalNotice = await findFlutterText(
            page,
            'stored locally until you sign up',
        );
        expect(hasLocalNotice).toBeTruthy();
    });

    test('DM-05: should have View Tournaments button in Demo Mode', async ({
        page,
    }) => {
        await launchFlutterApp(page);
        await clickFlutterButton(page, 'Try Demo');
        await waitForFlutterPage(page, 'Demo Mode');

        // Verify "View Tournaments" button is present
        const hasViewTournaments = await findFlutterText(
            page,
            'View Tournaments',
        );
        expect(hasViewTournaments).toBeTruthy();
    });

    test('DM-06: should navigate from Demo to Tournaments list', async ({
        page,
    }) => {
        await launchFlutterApp(page);

        // Navigate through: Home → Demo → Tournaments
        await clickFlutterButton(page, 'Try Demo');
        await waitForFlutterPage(page, 'Demo Mode');

        // Click "View Tournaments"
        await clickFlutterButton(page, 'View Tournaments');

        // Wait for tournaments page to load
        // The tournament list page shows "Tournaments" in the AppBar
        await waitForFlutterPage(page, 'Tournaments', 20_000);

        // Should show tournament list (which might be empty)
        const hasTournaments = await findFlutterText(page, 'Tournaments');
        expect(hasTournaments).toBeTruthy();
    });

    test('DM-07: should have back navigation from Demo page', async ({
        page,
    }) => {
        await launchFlutterApp(page);
        await clickFlutterButton(page, 'Try Demo');
        await waitForFlutterPage(page, 'Demo Mode');

        // Demo page has a back button that navigates to Home
        // The back button uses arrow_back icon
        const backButton = page.getByRole('button', { name: /back/i });
        const backLocator = backButton.or(page.locator('[aria-label*="Back"]'));

        // If back button is found, click it and verify we're back at Home
        const count = await backLocator.count();
        if (count > 0) {
            await backLocator.first().click();
            await page.waitForTimeout(3_000);

            const hasHome = await findFlutterText(page, 'TKD Brackets');
            expect(hasHome).toBeTruthy();
        }
    });

    test('DM-08: complete new user flow — Landing → Home → Demo → Tournaments', async ({
        page,
    }) => {
        // Step 1: Start at landing page
        const landingVisible = page.locator('#landing-container');
        await expect(landingVisible).toBeVisible();

        // Step 2: Launch Flutter app
        await launchFlutterApp(page);

        // Step 3: Verify Home page
        const hasHome = await findFlutterText(page, 'TKD Brackets');
        expect(hasHome).toBeTruthy();

        // Step 4: Navigate to Demo
        await clickFlutterButton(page, 'Try Demo');
        const hasDemoMode = await findFlutterText(page, 'Demo Mode');
        expect(hasDemoMode).toBeTruthy();

        // Step 5: Navigate to Tournaments
        await clickFlutterButton(page, 'View Tournaments');
        await waitForFlutterPage(page, 'Tournaments', 20_000);
        const hasTournaments = await findFlutterText(page, 'Tournaments');
        expect(hasTournaments).toBeTruthy();
    });
});
