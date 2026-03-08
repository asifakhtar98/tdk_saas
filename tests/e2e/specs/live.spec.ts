import { test, expect } from '@playwright/test';

// Configuration for generating unique data
const testUserEmail = `test-1772989018236@example.com`; // Created previously on Supabase
const testUserPassword = `password1234`;

test.describe('End to End Live Tests - Auth and Bracket Creation', () => {
    test.beforeEach(async ({ page }) => {
        page.on('console', msg => {
            if (msg.type() === 'error') {
                console.log(`[Browser Error]: ${msg.text()}`);
            } else {
                console.log(`[Browser]: ${msg.text()}`);
            }
        });
        await page.goto('/');

        // Start Flutter app
        const getStartedBtn = page.locator('#hero-cta-btn');
        await expect(getStartedBtn).toBeVisible({ timeout: 15000 });
        await getStartedBtn.click();
    });

    test('Authenticate and create new bracket', async ({ page }) => {
        test.setTimeout(120_000); // 120s timeout since these are real network calls

        // 1. Authentication Module
        await test.step('Login to the application', async () => {
            const signInBtnHome = page.getByText('Sign In', { exact: true });
            await expect(signInBtnHome).toBeVisible({ timeout: 45000 });
            await signInBtnHome.click();

            // Verify header
            await expect(page.getByText('Enter your email and password to continue')).toBeVisible({ timeout: 15000 });

            // Fill out credentials
            await page.getByLabel('Email Address').click();
            await page.getByLabel('Email Address').pressSequentially(testUserEmail);
            await page.getByLabel('Password').click();
            await page.getByLabel('Password').pressSequentially(testUserPassword);

            // Submit
            const signInSubmitBtn = page.getByRole('button', { name: 'Sign In', exact: true });
            await signInSubmitBtn.click();

            // Wait for successful login
            const dashboardHeader = page.getByRole('heading', { name: 'Dashboard' }).first();
            await expect(dashboardHeader).toBeVisible({ timeout: 15000 });
        });

        // 2. Tournament & Bracket Creation Module
        await test.step('Create tournament and divisions', async () => {
            // Workaround for Flutter Web 404s with simple http-server:
            // Client-side routing via History API matches Flutter's usePathUrlStrategy
            await page.evaluate(() => {
                window.history.pushState(null, '', '/tournaments');
                window.dispatchEvent(new Event('popstate'));
            });

            // Wait for the tournaments page
            await expect(page.getByRole('heading', { name: 'Tournaments' }).first()).toBeVisible({ timeout: 15000 });

            // Click Create Tournament
            const createBtn = page.getByRole('button', { name: 'Create Tournament' }).first();
            await expect(createBtn).toBeVisible({ timeout: 15000 });
            await createBtn.click();

            // Fill form
            await page.getByLabel('Tournament Name *').click();
            await page.getByLabel('Tournament Name *').pressSequentially(`Live E2E Tournament ${Date.now()}`);

            // Wait for "Select a date" inside form boundary just in case
            await page.getByText('Select a date').click();
            const okBtn = page.getByRole('button', { name: 'OK' });
            await expect(okBtn).toBeVisible();
            await okBtn.click();

            await page.getByRole('button', { name: 'Create', exact: true }).click();

            // Wait for creation success
            await expect(page.getByText('Tournament created successfully!')).toBeVisible({ timeout: 15000 });

            // Navigate to tournament detail (Wait for dialog to go)
            await expect(page.getByRole('heading', { name: 'Create Tournament' })).not.toBeVisible();

            // Look for the newly created tournament and click it
            const tournamentEntry = page.getByRole('group', { name: /Live E2E Tournament/i }).first();
            await expect(tournamentEntry).toBeVisible({ timeout: 15000 });
            await tournamentEntry.click();

            // Check for "Add Divisions"
            const addDivisionsBtn = page.getByRole('button', { name: 'Add Divisions' }).first();
            await expect(addDivisionsBtn).toBeVisible({ timeout: 15000 });
            await addDivisionsBtn.click();

            // Smart Division Builder Flow
            await expect(page.getByRole('heading', { name: 'Division Builder' })).toBeVisible();

            // Step 1: Federation (WT is default)
            await page.getByRole('button', { name: 'Continue' }).click();

            // Step 2: Age groups
            await page.getByRole('checkbox', { name: '18-32' }).click();
            await page.getByRole('button', { name: 'Continue' }).click();

            // Step 3: Belt groups
            await page.getByRole('checkbox', { name: 'Red - Black' }).click();
            await page.getByRole('button', { name: 'Continue' }).click();

            // Step 4: Weight classes
            await page.getByRole('button', { name: 'Continue' }).click();

            // Step 5: Create
            await page.getByRole('button', { name: 'Create Divisions' }).click();

            // Confirm creation
            await expect(page.getByRole('tab', { name: 'Divisions' })).toBeVisible({ timeout: 20000 });
            await page.getByRole('tab', { name: 'Divisions' }).click();

            // Should see a division
            await expect(page.getByRole('button', { name: /-54kg/ })).toBeVisible({ timeout: 10000 });
        });
    });
});
