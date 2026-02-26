import { defineConfig, devices } from '@playwright/test';

/**
 * Playwright configuration for TKD Brackets Flutter Web E2E tests.
 *
 * Expects the Flutter Web app to be running locally on port 8080.
 * Start with: cd tkd_brackets && flutter run -d chrome --web-port=8080
 *
 * Or build and serve:
 *   cd tkd_brackets && flutter build web
 *   npx serve tkd_brackets/build/web -l 8080
 */
export default defineConfig({
    testDir: './specs',
    timeout: 60_000,
    expect: {
        timeout: 15_000,
    },
    fullyParallel: false, // Flutter Web tests should run sequentially
    forbidOnly: !!process.env.CI,
    retries: process.env.CI ? 2 : 0,
    workers: 1,
    reporter: [
        ['html', { open: 'never' }],
        ['list'],
    ],
    use: {
        baseURL: process.env.BASE_URL || 'http://localhost:8080',
        trace: 'on-first-retry',
        screenshot: 'only-on-failure',
        video: 'on-first-retry',
        // Flutter Web specific: give it more time to load WASM/JS
        actionTimeout: 15_000,
        navigationTimeout: 30_000,
    },
    projects: [
        {
            name: 'chromium',
            use: {
                ...devices['Desktop Chrome'],
                viewport: { width: 1440, height: 900 }, // Desktop-first app
            },
        },
    ],
    // Optionally start a local server before tests
    // webServer: {
    //   command: 'cd ../../tkd_brackets && flutter run -d web-server --web-port=8080',
    //   port: 8080,
    //   reuseExistingServer: true,
    //   timeout: 120_000,
    // },
});
