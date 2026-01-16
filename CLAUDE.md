## ⛔ KRITISKA REGLER (BRYT ALDRIG)

1. **ENDAST** filer i denna katalog och underkataloger
2. **FÖRBJUDET:** `cd ..` eller åtkomst utanför projektroten
3. **ALLTID** kör oberoende agenter parallellt i samma meddelande
4. **Agentoutput:** berätta vad som gjorts och beslut – visa INTE kod

---

## Agentval

**Utforska/förstå:** `Explore` (ange thoroughness: quick/medium/very thorough)

**Kod:**
- JavaScript/Node → `javascript-pro`
- Fullstack/API → `nodejs-orchestrator`
- SwiftUI → `swiftui-developer`

**Kvalitet:**
- Granska kod → `code-reviewer` ← kör alltid efter ny kod
- Planera → `Plan`

**AI/LLM:**
- Prompts → `prompt-engineer`
- Arkitektur → `llm-architect`
- Implementation → `ai-engineer`
- Orkestrering → `agent-organizer`

**Övrigt:**
- UI/Design → `ui-designer`
- Moln → `cloud-architect` / `cloud-orchestrator`
- Git/terminal → `Bash`
- Osäker → `general-purpose`

---

## Parallella kombinationer (använd ofta)

- Ny feature: `Plan` + `Explore`
- Efter kodning: `code-reviewer` + `Bash` (tester)
- Fullstack: `nodejs-orchestrator` + `ui-designer`
- AI-projekt: `llm-architect` + `prompt-engineer` + `ai-engineer`
- Node + UI: `javascript-pro` + `ui-designer`
- iOS-projekt: `swiftui-developer` + `ui-designer`

---

## Project Overview

**Vitaly** - En iOS-hälsoapp som hämtar data från HealthKit, visar den i en WHOOP-inspirerad dashboard och använder AI för personliga hälsoinsikter.

| | |
|---|---|
| **Bundle ID** | com.perfectfools.vitaly |
| **App ID** | 6757679659 |
| **iOS Version** | 17.0+ |
| **Language** | Swift 5.9+ / SwiftUI |
| **Backend** | Firebase (Auth, Firestore) |
| **AI** | Google Gemini 2.0 Flash |

## Quick Deploy

| Kommando | Åtgärd | Tid |
|----------|--------|-----|
| `/deploy device` | Bygg & kör på iPhone | ~1 min |
| `/deploy sim` | Bygg & kör på Simulator | ~30 sek |
| `/deploy tf` | Ladda upp till TestFlight | ~3 min |

### Deploy Commands

```bash
# iPhone (Tony's iPhone 16 Pro)
xcodebuild -project Vitaly.xcodeproj -scheme Vitaly -configuration Debug \
  -destination 'platform=iOS,name=Tony – iPhone' -allowProvisioningUpdates build
xcrun devicectl device install app --device F4CB09B8-6394-55B6-BC8C-D9CF03AD0561 \
  ~/Library/Developer/Xcode/DerivedData/Vitaly-*/Build/Products/Debug-iphoneos/Vitaly.app
xcrun devicectl device process launch --device F4CB09B8-6394-55B6-BC8C-D9CF03AD0561 com.perfectfools.vitaly

# Simulator
xcodebuild -project Vitaly.xcodeproj -scheme Vitaly -configuration Debug \
  -destination 'platform=iOS Simulator,id=A745E301-55E9-46F7-B77A-5B8A8ECC0C5A' build

# TestFlight
fastlane beta
```

## Device IDs

| Device | ID |
|--------|-----|
| Tony's iPhone 16 Pro | `F4CB09B8-6394-55B6-BC8C-D9CF03AD0561` |
| iPhone 17 Pro Simulator | `A745E301-55E9-46F7-B77A-5B8A8ECC0C5A` |

## Project Structure

```
iOSHealth/
├── App/
│   ├── VitalyApp.swift              # @main entry, Firebase config
│   └── AppCoordinator.swift         # Auth state, navigation, onboarding
├── Core/
│   ├── Services/
│   │   ├── AuthService.swift        # Firebase Auth + Apple Sign-In
│   │   ├── HealthKitService.swift   # HealthKit queries
│   │   ├── GeminiService.swift      # AI with ExtendedHealthContext
│   │   ├── BodyMeasurementService.swift  # Weight/waist tracking
│   │   └── GLP1Service.swift        # GLP-1 medication tracking
│   └── Models/
│       ├── User.swift               # User profile with birthDate, heightCm
│       ├── SleepData.swift, ActivityData.swift, HeartData.swift
│       └── AIInsight.swift
├── Features/
│   ├── Auth/Views/                  # LoginView, OnboardingView (5 pages)
│   ├── Dashboard/Views/             # DashboardView, MainTabView
│   ├── Fitness/Views/               # FitnessView (no NavigationStack!)
│   ├── Biology/Views/               # BiologyView, WeightChartView, WaistChartView
│   ├── AI/Views/                    # AIInsightsView, AIChatView
│   └── Settings/Views/              # SettingsView (Developer section)
└── Resources/
    ├── Info.plist
    └── Secrets.plist                # GEMINI_API_KEY
```

## Brand Colors

| Color | Hex | Usage |
|-------|-----|-------|
| Primary | `#F27340` | Buttons, accents |
| Background | `#0D0D12` | Deep black |
| Card | `#1A1A1F` | Card background |
| Sleep | `#9980D9` | Purple |
| Activity | `#F28C4D` | Orange |
| Heart | `#F25966` | Coral red |
| Recovery | `#FFB359` | Golden |

Use: `Color.vitalyPrimary`, `Color.vitalyBackground`, `LinearGradient.vitalyGradient`

## Key Implementation Notes

### Horizontal Scroll Prevention
All ScrollViews must have these modifiers to prevent horizontal dragging:
```swift
.scrollBounceBehavior(.basedOnSize)
.clipped()
.contentShape(Rectangle())
```

### Onboarding
- Uses `UserDefaults` with key `hasCompletedOnboarding_{userId}`
- User ID fallback: `user.id ?? user.phoneNumber`
- No swipe between pages - button navigation only
- Consent checkbox required on Medical Disclaimer page

### AI Context
All AI functions (Daily Summary, Sleep Analysis, Recovery Advice, Chat) have access to:
- 30 days of health data (sleep, activity, heart)
- Sleep stages (REM, deep, light, awake) with percentages
- Body measurements (weight, waist)
- GLP-1 treatment info
- User profile (name, age, height)

Via `ExtendedHealthContext` in GeminiService.

### AI Rules (IMPORTANT)
1. **All prompts must be in English** - Never use Swedish in AI prompts
2. **Never mention nutrition/diet** - We don't have nutrition data, so AI must never give dietary advice
3. **No markdown formatting** - AI responses should be plain text (no **bold**, *italic*, bullets, emojis)

Add to all prompts:
```
IMPORTANT: Do NOT use any markdown formatting. Write plain text only.
NEVER mention nutrition, diet, food, eating, meals, or any dietary advice.
```

### AI Caching
AI insights are cached in UserDefaults to reduce API calls:
- Cache key: `ai_insight_cache_{type}`
- Valid if: same hour + same day + same data hash
- Cached methods: `generateDailyOverview`, `generateMetricInsight`, `generateSleepInsight`
- Clear cache: `GeminiService.shared.clearCache()`

### Sleep Stages
SleepData includes detailed sleep stages:
- `deepSleep` (seconds) - Goal: ≥15% of total
- `remSleep` (seconds) - Goal: ≥20% of total
- `lightSleep` (seconds)
- `awake` (seconds) - Goal: ≤10% of total

Display format: Use hours and minutes (e.g., "4h 49m" not "289m")

### FitnessView
**Important:** FitnessView must NOT have a NavigationStack wrapper - it causes gesture conflicts with TabView.

## Fastlane

```bash
fastlane beta  # Builds, signs, uploads to TestFlight (~3 min)
```

API Key: `AuthKey_WW3CKRBFQ2.p8` in project root (no 2FA needed)

## App Store

| | |
|---|---|
| Support URL | https://tonsaj.github.io/vitaly/support.html |
| Privacy URL | https://tonsaj.github.io/vitaly/privacy.html |
| Category | Health & Fitness |
| Age Rating | 4+ |

### Keywords (EN)
health,sleep,heart,hrv,recovery,strain,fitness,wellness,tracker,healthkit,ai,insights

## MCP Tools (Xcode)

| Tool | Description |
|------|-------------|
| `mcp__xcode__xcode_build` | Build project |
| `mcp__xcode__xcode_run` | Run on simulator |
| `mcp__xcode__xcode_screenshot` | Take simulator screenshot |
| `mcp__xcode__xcode_errors` | Get build errors |
