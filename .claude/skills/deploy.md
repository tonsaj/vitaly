# Deploy Skill for Vitaly iOS App

This skill handles all deployment scenarios for the Vitaly iOS health app.

## Usage

When the user says any of these:
- `/deploy` - Show deployment options
- `/deploy device` or `/deploy phone` - Build and run on physical iPhone
- `/deploy simulator` or `/deploy sim` - Build and run on iOS Simulator
- `/deploy testflight` or `/deploy tf` - Upload to TestFlight
- `/deploy appstore` - Upload to App Store Connect (without review)

## Project Configuration

```
Project: Vitaly.xcodeproj
Scheme: Vitaly
Bundle ID: com.perfectfools.vitaly
iPhone Device ID: F4CB09B8-6394-55B6-BC8C-D9CF03AD0561 (Tony's iPhone 16 Pro)
Simulator ID: A745E301-55E9-46F7-B77A-5B8A8ECC0C5A (iPhone 17 Pro)
Working Directory: /Users/tonsaj/Workspace/iOSHealth
```

## Commands

### 1. Deploy to Physical Device (`/deploy device`)

Build, install, and launch on Tony's iPhone:

```bash
# Build
xcodebuild -project /Users/tonsaj/Workspace/iOSHealth/Vitaly.xcodeproj \
  -scheme Vitaly \
  -configuration Debug \
  -destination 'platform=iOS,name=Tony – iPhone' \
  -allowProvisioningUpdates build

# Install
xcrun devicectl device install app \
  --device F4CB09B8-6394-55B6-BC8C-D9CF03AD0561 \
  ~/Library/Developer/Xcode/DerivedData/Vitaly-drjgsnbduzeaiagotparrbsicdjb/Build/Products/Debug-iphoneos/Vitaly.app

# Launch
xcrun devicectl device process launch \
  --device F4CB09B8-6394-55B6-BC8C-D9CF03AD0561 \
  com.perfectfools.vitaly
```

**Notes:**
- If device is locked, wait for user to unlock and retry launch
- Build takes ~30-60 seconds
- Install takes ~5-10 seconds

### 2. Deploy to Simulator (`/deploy simulator`)

Build and run on iOS Simulator:

```bash
# Build for simulator
xcodebuild -project /Users/tonsaj/Workspace/iOSHealth/Vitaly.xcodeproj \
  -scheme Vitaly \
  -configuration Debug \
  -destination 'platform=iOS Simulator,id=A745E301-55E9-46F7-B77A-5B8A8ECC0C5A' \
  build

# Or use MCP tool
mcp__xcode__xcode_build(project_path, scheme, simulator_id)
mcp__xcode__xcode_run(bundle_id)
```

### 3. Deploy to TestFlight (`/deploy testflight`)

Upload to TestFlight for beta testing:

```bash
cd /Users/tonsaj/Workspace/iOSHealth
fastlane beta
```

**What fastlane beta does:**
1. Increments build number (timestamp format: YYYYMMDDHHMM)
2. Builds Release configuration
3. Signs with App Store distribution profile
4. Uploads to TestFlight
5. Skips waiting for processing

**API Key:** `AuthKey_WW3CKRBFQ2.p8` (no 2FA required)
**Total time:** ~3 minutes

### 4. Deploy to App Store (`/deploy appstore`)

Same binary as TestFlight - just submit for review in App Store Connect.

The TestFlight upload (`fastlane beta`) also makes the build available in App Store Connect. To submit:
1. Go to App Store Connect
2. Select the build from TestFlight
3. Add to a new version
4. Submit for review

## Quick Reference

| Command | Action | Time |
|---------|--------|------|
| `/deploy device` | Build & run on iPhone | ~1 min |
| `/deploy sim` | Build & run on Simulator | ~30 sec |
| `/deploy tf` | Upload to TestFlight | ~3 min |
| `/deploy appstore` | Instructions for App Store | - |

## Error Handling

### Device Locked
```
ERROR: The device is locked.
```
→ Ask user to unlock iPhone, wait 5 seconds, retry launch command

### Provisioning Issues
```
ERROR: No profiles found
```
→ Add `-allowProvisioningUpdates` to xcodebuild command

### Build Failures
→ Run `mcp__xcode__xcode_errors` to get detailed error messages

## Response Format

When deploying, provide:
1. Short status message for each step
2. Final confirmation with build number (for TestFlight)
3. Don't show full command output - just success/failure

Example:
```
Building for iPhone... ✓
Installing... ✓
Launching... ✓
Vitaly is now running on your iPhone!
```
