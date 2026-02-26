import { test, expect } from '@playwright/test';

test.describe('New User Journey Flow', () => {
    test('should progress from landing page to demo mode successfully', async ({ page, browserName }) => {

        // Enhancement: Listen to and forward any unhandled Flutter/Browser console errors 
        // straight to the developer's terminal for easier debugging
        page.on('console', msg => {
            if (msg.type() === 'error') {
                console.log(`[Browser Console Error] : ${msg.text()}`);
            }
        });

        // Enhancement: Forward page uncaught exceptions
        page.on('pageerror', exception => {
            console.log(`[Uncaught Page Exception] : ${exception}`);
        });

        await test.step('Navigate to the HTML landing page', async () => {
            await page.goto('/');
        });

        await test.step('Interact with Marketing CTA', async () => {
            const getStartedBtn = page.locator('#hero-cta-btn');
            await expect(getStartedBtn, 'Marketing CTA should be visible immediately before Flutter loads').toBeVisible();
            await getStartedBtn.click();
        });

        await test.step('Wait for Flutter WASM/JS bundle sequence to complete', async () => {
            const tryDemoBtn = page.getByText('Try Demo', { exact: true });
            const homeTitle = page.getByText('Tournament Bracket Management');
            const signInBtn = page.getByText('Sign In', { exact: true });

            // Using custom error messages in expect() provides rich developer feedback in the terminal/HTML report 
            await expect(tryDemoBtn, 'Flutter app failed to load or "Try Demo" button is missing').toBeVisible({ timeout: 45000 });
            await expect(homeTitle, 'Flutter Home Page did not render the correct title').toBeVisible();
            await expect(signInBtn, '"Sign In" button should be rendered on the Home Page').toBeVisible();
        });

        await test.step('Validate Authorization Placeholder (Story 2.4)', async () => {
            const signInBtn = page.getByText('Sign In', { exact: true });
            await signInBtn.click();

            const snackbarText = page.getByText('Sign in available in Story 2.4').first();
            await expect(snackbarText, 'Snackbar not shown when clicking Sign In').toBeVisible({ timeout: 15000 });
        });

        await test.step('Proceed from Home Page to unauthenticated Demo Mode', async () => {
            const tryDemoBtn = page.getByText('Try Demo', { exact: true });

            // Using force:true handles edge cases where flutter overlay elements (like snackbars) 
            // obscure the button momentarily during transitions
            await tryDemoBtn.click({ force: true });

            const demoPageHeader = page.getByText('Explore TKD Brackets');
            await expect(demoPageHeader, 'Demo page failed to load or render header properly').toBeVisible({ timeout: 15000 });

            const viewTournamentsBtn = page.getByText('View Tournaments');
            await expect(viewTournamentsBtn, 'Demo page is missing "View Tournaments" CTA').toBeVisible();
        });

        await test.step('Final visual inspection buffer (Enhancement)', async () => {
            // Enhancement: Save a visual snapshot of the ending state automatically
            const fileName = `test-results/journey-completion-${browserName}.png`;
            await page.screenshot({ path: fileName, fullPage: true });

            // Enhancement: Allow the browser to remain open for 3 seconds before disposing 
            // the context so developers can physically see what happened.
            await page.waitForTimeout(3000);
        });
    });
});
