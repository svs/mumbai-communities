# Cypress End-to-End Tests

## Setup

1. Install dependencies:
   ```bash
   npm install
   ```

2. Make sure the Rails server is running on port 4090:
   ```bash
   # If not running, start it:
   bin/rails server -p 4090
   ```

## Running Tests

### Interactive Mode (Recommended for Development)
```bash
npm run cypress:open
# or
npm run test:e2e:open
```

### Headless Mode (CI/Testing)
```bash
npm run cypress:run
# or
npm run test:e2e
```

## Test Files

- `cypress/e2e/boundary_tracing.cy.js` - Main boundary tracing interface tests

## Key Features Tested

1. **Image Loading**: Verifies PNG images load instead of PDFs
2. **Google Maps Integration**: Tests map initialization and controls
3. **Drawing Controls**: Tests opacity sliders, PDF controls, map controls
4. **Mode Switching**: Tests draw/pan mode toggling
5. **Form Structure**: Verifies boundary submission form setup

## Notes

- Tests assume prabhag 68 (Ward A, Prabhag 225) exists in the database
- Authentication may need to be adjusted based on your Devise setup
- Google Maps interactions are limited in Cypress but basic functionality is tested
- For full drawing interaction testing, consider manual testing or specialized Google Maps testing tools

## Troubleshooting

- If Google Maps doesn't load, check your `GOOGLE_MAPS_API_KEY` environment variable
- If images don't load, verify the `public/prabhag_images/` directory contains the converted PNG files
- Make sure the Rails server is accessible at `http://localhost:4090`