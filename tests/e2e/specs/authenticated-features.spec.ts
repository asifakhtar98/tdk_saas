import { test, expect } from '@playwright/test';

test.describe('Authenticated Feature Flows (via Demo Mode)', () => {

    test.beforeEach(async ({ page }) => {
        page.on('console', msg => console.log('BROWSER CONSOLE:', msg.text()));
        // Shared entry point: Start the app and enter Demo Mode
        await page.goto('/');
        await page.locator('#hero-cta-btn').click();

        // Wait for Flutter and click Try Demo
        const tryDemoBtn = page.getByText('Try Demo', { exact: true });
        await expect(tryDemoBtn).toBeVisible({ timeout: 45000 });
        await tryDemoBtn.click();

        // Ensure we are on the Demo landing page
        await expect(page.getByText('Explore TKD Brackets')).toBeVisible();
    });

    test('should allow creating and viewing a tournament', async ({ page }) => {
        // 1. Navigate to Tournament List
        await page.getByText('View Tournaments').click();
        await expect(page.getByText('Tournaments', { exact: true }).first()).toBeVisible();

        // 2. Open Create Tournament Dialog
        const createBtn = page.getByRole('button', { name: 'Create Tournament' }).first();
        await createBtn.click();

        // 3. Fill out the form
        await page.getByLabel('Tournament Name *').click();
        await page.getByLabel('Tournament Name *').pressSequentially('E2E Test Tournament');
        await page.getByLabel('Description').click();
        await page.getByLabel('Description').pressSequentially('This tournament was created by an automated E2E test.');

        // Select Date
        await page.getByText('Select a date').click();
        const okBtn = page.getByRole('button', { name: 'OK' });
        await expect(okBtn).toBeVisible();
        await okBtn.click();

        // Verify date is selected (text changed from 'Select a date')
        await expect(page.getByText('Select a date')).not.toBeVisible();

        // 4. Submit
        await page.getByRole('button', { name: 'Create', exact: true }).click();

        // 5. Verify creation (wait for snackbar and list entry)
        // Check if there's a validation error snackbar
        const errorSnackbar = page.getByText('Please select a tournament date');
        if (await errorSnackbar.isVisible()) {
            throw new Error("Date validation failed - date picker interaction didn't work");
        }

        await expect(page.getByText('Tournament created successfully!')).toBeVisible({ timeout: 15000 });
        const tournamentEntry = page.getByRole('group', { name: /E2E Test Tournament/i }).first();
        await expect(tournamentEntry).toBeVisible({ timeout: 5000 });

        // 6. Navigate to tournament detail (Wait for dialog to go)
        await expect(page.getByRole('heading', { name: 'Create Tournament' })).not.toBeVisible();
        await tournamentEntry.click();
        await expect(page.getByRole('heading', { name: 'E2E Test Tournament' })).toBeVisible({ timeout: 15000 });
    });

    test('should navigate through tournament management sub-features', async ({ page }) => {
        test.setTimeout(120000);
        // Navigate to Tournament List
        await page.getByText('View Tournaments').click();

        // Create a tournament
        await page.getByRole('button', { name: 'Create Tournament' }).first().click();
        await page.getByLabel('Tournament Name *').click();
        await page.getByLabel('Tournament Name *').pressSequentially('Management Test');
        await page.getByText('Select a date').click();
        await page.getByRole('button', { name: 'OK' }).click();
        await page.getByRole('button', { name: 'Create', exact: true }).click();

        // Wait for it to appear
        const tournamentEntry = page.getByRole('group', { name: /Management Test/i }).first();
        await expect(tournamentEntry).toBeVisible({ timeout: 20000 });

        // Open the tournament
        await tournamentEntry.click();

        // Check for "Add Divisions" button on Overview tab
        const addDivisionsBtn = page.getByRole('button', { name: 'Add Divisions' }).first();
        await expect(addDivisionsBtn).toBeVisible({ timeout: 15000 });
        await addDivisionsBtn.click();

        await expect(page.getByRole('heading', { name: 'Division Builder' })).toBeVisible();
        // Go through wizard
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

        // Step 5: Review
        // The button changes to 'Create Divisions'
        await page.getByRole('button', { name: 'Create Divisions' }).click();

        // Wait for tournament detail page navigation.
        await expect(page.getByRole('tab', { name: 'Divisions' })).toBeVisible({ timeout: 20000 });

        // Switch to Divisions tab
        await page.getByRole('tab', { name: 'Divisions' }).click();

        // We should no longer see "No divisions yet"
        await expect(page.getByRole('tabpanel', { name: 'No divisions yet' })).not.toBeVisible();

        // We should see a division item created
        await expect(page.getByRole('button', { name: /-54kg/ })).toBeVisible({ timeout: 10000 });
    });
});
