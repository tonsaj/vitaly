# Screenshots Skill for Vitaly iOS App

This skill handles taking App Store screenshots on iOS Simulator.

## Usage

When the user says any of these:
- `/screenshots` - Take screenshots on current simulator
- `/screenshots all` - Take screenshots on multiple simulator sizes
- `/screenshots [screen]` - Take screenshot of specific screen (dashboard, fitness, biology, ai, settings)

## Project Configuration

```
Project: Vitaly.xcodeproj
Scheme: Vitaly
Bundle ID: com.perfectfools.vitaly
Screenshot Output: /Users/tonsaj/Workspace/iOSHealth/screenshots/
```

## Simulator IDs

| Device | ID | Display | Use For |
|--------|-----|---------|---------|
| iPhone 16 Pro Max | 6E05C6C3-A58A-43F4-B919-7A741CED990D | 6.7" | App Store (required) |
| iPhone 16 Pro | FF53F5A9-2EC7-489A-BB4B-96D81515B799 | 6.3" | Alternative |
| iPhone 17 Pro | A745E301-55E9-46F7-B77A-5B8A8ECC0C5A | 6.3" | Development |

## App Store Screenshot Requirements

| Device Size | Resolution | Required |
|-------------|------------|----------|
| 6.7" Display | 1290 x 2796 | Yes (iPhone 15 Pro Max) |
| 6.5" Display | 1284 x 2778 | Optional |
| 5.5" Display | 1242 x 2208 | Optional |

## Commands

### 1. Take Screenshots (`/screenshots`)

Steps to take screenshots:

```bash
# 1. Create screenshots directory
mkdir -p /Users/tonsaj/Workspace/iOSHealth/screenshots

# 2. Boot simulator (if not running)
xcrun simctl boot A745E301-55E9-46F7-B77A-5B8A8ECC0C5A

# 3. Open Simulator app
open -a Simulator
```

Then use MCP tools:
1. `mcp__xcode__xcode_build` - Build the app for simulator
2. `mcp__xcode__xcode_run` - Launch the app
3. `mcp__xcode__xcode_screenshot` - Take screenshot

### 2. Screenshot Workflow

**Step 1: Prepare Simulator**
```bash
# Boot simulator
xcrun simctl boot A745E301-55E9-46F7-B77A-5B8A8ECC0C5A

# Open Simulator app to see it
open -a Simulator

# Wait for boot
sleep 3
```

**Step 2: Build and Install App**
Use `mcp__xcode__xcode_build`:
- project_path: /Users/tonsaj/Workspace/iOSHealth/Vitaly.xcodeproj
- scheme: Vitaly
- simulator_id: A745E301-55E9-46F7-B77A-5B8A8ECC0C5A

**Step 3: Launch App**
Use `mcp__xcode__xcode_run`:
- bundle_id: com.perfectfools.vitaly
- simulator_id: A745E301-55E9-46F7-B77A-5B8A8ECC0C5A

**Step 4: Take Screenshots**
Use `mcp__xcode__xcode_screenshot`:
- simulator_id: A745E301-55E9-46F7-B77A-5B8A8ECC0C5A
- output_path: /Users/tonsaj/Workspace/iOSHealth/screenshots/[name].png

### 3. Screenshot Names

Use these filenames for App Store:
```
screenshots/01_dashboard.png      - Main dashboard view
screenshots/02_fitness.png        - Fitness/activity view
screenshots/03_biology.png        - Biology/measurements view
screenshots/04_ai_insights.png    - AI insights view
screenshots/05_sleep.png          - Sleep details
screenshots/06_settings.png       - Settings view
```

### 4. Multiple Simulator Sizes (`/screenshots all`)

To get all required sizes, create simulators for each device:

```bash
# List available device types
xcrun simctl list devicetypes | grep iPhone

# Create new simulator (if needed)
xcrun simctl create "iPhone 15 Pro Max" "com.apple.CoreSimulator.SimDeviceType.iPhone-15-Pro-Max"
```

## Response Format

When taking screenshots, provide:
1. Status for each step (boot, build, run)
2. Confirmation when screenshot is saved
3. Path to screenshot file

Example:
```
Booting simulator... OK
Building app... OK
Launching app... OK
Taking screenshot of Dashboard... OK

Screenshot saved to: screenshots/01_dashboard.png

Navigate to the next screen and run /screenshots again,
or specify: /screenshots fitness
```

## Manual Navigation Hint

After launching the app, tell the user:
- Appen körs nu i simulatorn
- Navigera till den vy du vill ta skärmdump av
- Skriv /screenshots för att ta skärmdumpen
- Eller vänta 5 sekunder så tar jag en automatiskt

## Full Automated Flow

For `/screenshots all`:

1. Boot simulator
2. Build and install app
3. Launch app
4. Wait 3 seconds for app to load
5. Take screenshot (Dashboard)
6. Ask user to navigate to next screen OR use accessibility to tap tabs
7. Repeat for each screen

## Using xcrun simctl for Screenshots (Alternative)

If MCP tool has issues:
```bash
xcrun simctl io A745E301-55E9-46F7-B77A-5B8A8ECC0C5A screenshot /Users/tonsaj/Workspace/iOSHealth/screenshots/screenshot.png
```

## Troubleshooting

### Simulator Not Booting
```bash
# Check status
xcrun simctl list devices | grep -A5 "iOS"

# Force shutdown and reboot
xcrun simctl shutdown A745E301-55E9-46F7-B77A-5B8A8ECC0C5A
xcrun simctl boot A745E301-55E9-46F7-B77A-5B8A8ECC0C5A
```

### App Not Installing
- Rebuild with clean: `xcodebuild clean build ...`
- Check that simulator architecture matches (arm64 for Apple Silicon)

### Screenshot Black/Empty
- Wait longer after launching app (sleep 5)
- Check that app is actually running: `xcrun simctl listapps booted`
