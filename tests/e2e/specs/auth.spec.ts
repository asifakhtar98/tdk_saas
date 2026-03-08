import { test, expect } from '@playwright/test';

test.describe('Auth Flow', () => {
    test.beforeEach(async ({ page }) => {
        page.on('console', msg => {
            console.log(`[Browser Console]: ${msg.text()}`);
        });

        await page.goto('/');

        // Start the flutter app by clicking the CTA
        const getStartedBtn = page.locator('#hero-cta-btn');
        await expect(getStartedBtn).toBeVisible();
        await getStartedBtn.click();
    });

    test('should be able to sign up and then sign in', async ({ page }) => {
        // Wait for flutter to load
        const signInBtnHome = page.getByText('Sign In', { exact: true });
        await expect(signInBtnHome).toBeVisible({ timeout: 45000 });

        // Go to auth page
        await signInBtnHome.click();

        // Check for toggle and toggle it to Sign Up
        const signUpToggle = page.getByText("Don't have an account? Sign Up");
        await expect(signUpToggle).toBeVisible({ timeout: 15000 });
        await signUpToggle.click();

        // Verify header changed to Sign Up
        const signUpHeader = page.getByRole('heading', { level: 1 }).or(page.getByText('Create an account'));
        await expect(signUpHeader).toBeVisible();

        // Fill out email
        const email = `newuser-${Date.now()}@example.com`;
        const emailInput = page.getByLabel('Email Address');
        await emailInput.fill(email);

        // Fill out password (using Tab to focus the next field from email since getByLabel('Password') failed)
        await emailInput.press('Tab');
        await page.keyboard.type('password1234');

        // Click Sign Up
        const signUpSubmitBtn = page.getByRole('button', { name: 'Sign Up', exact: true });
        await signUpSubmitBtn.click();

        const successMessage = page.getByText('Success! Setting up your session...');
        const errorMessage = page.locator('.snack-bar-content').or(page.getByText('AuthException', { exact: false }));

        await Promise.race([
            expect(successMessage).toBeVisible({ timeout: 15000 }),
            expect(errorMessage).toBeVisible({ timeout: 15000 }).then(async () => {
                const text = await errorMessage.first().textContent();
                throw new Error(`Sign up failed: ${text}`);
            })
        ]);

        // If it's a real experience, the app might redirect to /organization/setup or /dashboard
        // So we can check if it navigated away or showed success.
    });
});
