---
name: maestro
description: Run Maestro E2E tests for iOS or Android
---

# Maestro E2E Testing

Run Maestro end-to-end tests for the MedTasker app.

## Usage

```
/maestro <platform>
```

Where `<platform>` is:
- `android` - Build release for Android and run tests
- `ios` - Build release for iOS and run tests

## Prerequisites
- Maestro CLI installed
- Android emulator or iOS simulator running
- `.env.maestro` configured with test credentials

## Commands Reference

Build for Android (release):
```bash
pnpm e2e:build-android
```

Build for iOS (release):
```bash
pnpm e2e:build-ios
```

Run all tests:
```bash
pnpm e2e:run
```

## Test Structure
- `e2e/config.yaml` - Maestro configuration
- `e2e/tests/` - Test flow files
- `e2e/steps/` - Reusable step files

## Task

Based on `$ARGUMENTS`:

1. **If `android`**:
   - Verify Android emulator is running (`adb devices`)
   - Build the release version: `pnpm e2e:build-android`
   - Run Maestro tests: `pnpm e2e:run`

2. **If `ios`**:
   - Verify iOS simulator is running (`xcrun simctl list devices | grep Booted`)
   - Build the release version: `pnpm e2e:build-ios`
   - Run Maestro tests: `pnpm e2e:run`

3. **If no arguments or unrecognized**:
   - Ask the user which platform to use (android or ios)
