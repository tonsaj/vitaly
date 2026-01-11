# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Vitaly** - En svensk iOS-hälsoapp inspirerad av Bevel Health. Hämtar hälsodata från HealthKit, visar den i en dashboard och använder AI för att analysera och ge personliga hälsoinsikter.

*Tagline: "Din hälsa, förenklad"*

## Tech Stack

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI (iOS 17+ features, @Observable)
- **Minimum iOS**: 17.0
- **Architecture**: MVVM
- **Backend**: Firebase (Auth, Firestore)
- **AI**: Google Gemini 2.0 Flash via Google AI SDK
- **Health Data**: Apple HealthKit
- **Charts**: Swift Charts

## Brand Colors (Dark Theme)

| Färg | Hex | Användning |
|------|-----|------------|
| Primary | `#F27340` | Warm orange - knappar, accenter |
| Secondary | `#FA9973` | Coral/peach - gradienter |
| Tertiary | `#FFC7A6` | Light peach - gradient highlights |
| Background | `#0D0D12` | Deep black |
| Card | `#1A1A1F` | Dark card background |
| Text Primary | `#F2F2F2` | Off-white text |
| Text Secondary | `#99948C` | Warm gray |
| Sleep | `#9980D9` | Soft purple |
| Activity | `#F28C4D` | Warm orange |
| Heart | `#F25966` | Coral red |
| Recovery | `#FFB359` | Golden |

**Design inspirerad av:** Mörkt tema med varma sunset-gradienter och organiska kurvor.

## Build Commands

```bash
# Generate Xcode project (requires XcodeGen)
brew install xcodegen
cd /Users/tonsaj/Workspace/iOSHealth
xcodegen generate

# Open project
open Vitaly.xcodeproj

# Build
xcodebuild -project Vitaly.xcodeproj -scheme Vitaly -sdk iphonesimulator build

# Run tests
xcodebuild -project Vitaly.xcodeproj -scheme Vitaly -sdk iphonesimulator test
```

## Claude Code + Xcode Integration

Projektet har en integrerad Xcode MCP-server och build-scripts för automatisering.

### MCP-server verktyg (efter omstart av Claude Code)

| Verktyg | Beskrivning |
|---------|-------------|
| `xcode_open` | Öppna projekt i Xcode |
| `xcode_build` | Bygga projekt, returnerar fel |
| `xcode_run` | Installera och köra på simulator |
| `xcode_screenshot` | Ta skärmdump av simulator |
| `xcode_errors` | Hämta senaste build-fel |
| `xcode_simulators` | Lista tillgängliga simulatorer |
| `xcode_boot_simulator` | Starta en simulator |
| `xcode_resolve_packages` | Lösa SPM-beroenden |

### Build Scripts

```bash
# Bygg projektet
./scripts/build.sh

# Bygg och kör på simulator
./scripts/build.sh --run

# Bygg, kör och ta skärmdump
./scripts/build.sh --run --screenshot

# Lösa paketberoenden (vid SPM-problem)
./scripts/build.sh --resolve
```

### Hooks

Efter varje Swift-redigering körs automatisk syntax-kontroll via `swift-check.sh`.

### Konfigurationsfiler

- `.mcp.json` - MCP-server konfiguration
- `.claude/settings.json` - Hooks och miljövariabler
- `scripts/build.sh` - Huvudbyggskript
- `scripts/swift-check.sh` - Syntax-kontroll

## Project Structure

```
iOSHealth/
├── App/
│   ├── VitalyApp.swift              # @main entry, Firebase config
│   └── AppCoordinator.swift         # Auth state, navigation
├── Core/
│   ├── Services/
│   │   ├── AuthService.swift        # Firebase Auth + Apple Sign-In
│   │   ├── HealthKitService.swift   # All HealthKit queries
│   │   ├── GeminiService.swift      # AI (gemini-2.0-flash)
│   │   ├── FirestoreService.swift   # Database operations
│   │   └── SyncService.swift        # HealthKit → Firestore sync
│   ├── Models/
│   │   ├── User.swift, HealthMetric.swift
│   │   ├── SleepData.swift, ActivityData.swift
│   │   ├── HeartData.swift, AIInsight.swift
│   └── Extensions/
│       ├── Date+Extensions.swift
│       ├── Color+Extensions.swift
│       ├── Color+Vitaly.swift       # Brand colors
│       └── View+Extensions.swift
├── Features/
│   ├── Auth/Views/                  # LoginView, SignUpView, OnboardingView
│   ├── Dashboard/Views/             # DashboardView, MetricCardView, MainTabView
│   ├── Health/Views/                # SleepDetailView, ActivityDetailView, HeartRateView, RecoveryView
│   ├── AI/Views/                    # AIInsightsView, AIChatView, InsightCardView
│   └── Settings/Views/              # SettingsView
├── Resources/
│   ├── Info.plist                   # HealthKit permissions
│   └── Assets.xcassets              # App icon, colors
└── Supporting/
    └── APIConfig.swift              # Gemini API key loader
```

## Entitlements

Required capabilities (iOSHealth.entitlements):
- `com.apple.developer.healthkit` - HealthKit access
- `com.apple.developer.healthkit.background-delivery` - Background updates
- `com.apple.developer.applesignin` - Sign in with Apple

## Dependencies

```yaml
packages:
  Firebase:
    url: https://github.com/firebase/firebase-ios-sdk
    from: "11.0.0"
  GoogleGenerativeAI:
    url: https://github.com/google/generative-ai-swift
    from: "0.5.0"
```

Products: FirebaseAuth, FirebaseFirestore, GoogleGenerativeAI

## AI Integration

Google AI SDK med Gemini 2.0 Flash:

```swift
import GoogleGenerativeAI

let model = GenerativeModel(name: "gemini-2.0-flash", apiKey: apiKey)
let response = try await model.generateContent(prompt)
```

API-nyckel: https://aistudio.google.com/app/apikey

## Setup

1. `xcodegen generate`
2. Skapa Firebase-projekt → ladda ner `GoogleService-Info.plist` → lägg i `Resources/`
3. Aktivera Authentication (Email + Apple) och Firestore i Firebase Console
4. Skapa `Resources/Secrets.plist`:
   ```xml
   <dict>
       <key>GEMINI_API_KEY</key>
       <string>din-api-nyckel</string>
   </dict>
   ```
5. Sätt `DEVELOPMENT_TEAM` i `project.yml`
6. Öppna i Xcode, bygg och kör

## Firestore Structure

```
users/{userId}/
├── profile: { name, email, createdAt, settings }
├── healthData/{yyyy-MM-dd}/
│   ├── sleep: { totalDuration, deepSleep, remSleep, ... }
│   ├── activity: { steps, calories, distance, workouts[] }
│   └── heart: { restingHeartRate, hrv, ... }
└── insights/{insightId}/
    └── { type, title, content, createdAt, isRead }
```

## Key Patterns

- **@Observable** (iOS 17): Används i alla ViewModels
- **async/await**: All data fetching
- **Swedish UI**: Alla strängar på svenska
- **Swift Charts**: TrendChartView för grafer
- **MVVM**: Varje Feature har Views/ och ViewModels/
- **Vitaly Colors**: Använd `Color.vitalyPrimary`, `LinearGradient.vitalyGradient`, etc.

## Agenter

**Använd alltid lämplig agent (eller flera parallellt) när uppgiften matchar agentens beskrivning:**

### Utveckling & Kod

| Agent | Användning |
|-------|-----------|
| `javascript-pro` | Node.js 20+, ES2023+, async patterns, performance, tester |
| `nodejs-orchestrator` | Bygga/scaffolda Node.js/HTML-projekt med parallell delegering |
| `swiftui-developer` | SwiftUI UI, animationer, state management, accessibility |
| `code-reviewer` | Kodgranskning, säkerhet, PRs, best practices |

### Utforskning & Planering

| Agent | Användning |
|-------|-----------|
| `Explore` | Snabb kodbas-utforskning, hitta filer/patterns, förstå struktur |
| `Plan` | Arkitektur, implementation-strategi, steg-för-steg planering |
| `general-purpose` | Komplexa multi-steg uppgifter, research, kod-sökning |

### AI & LLM

| Agent | Användning |
|-------|-----------|
| `prompt-engineer` | Prompt-design, optimering, evaluation frameworks |
| `llm-architect` | LLM-arkitektur, fine-tuning, deployment, serving |
| `ai-engineer` | AI-system design, modell-implementation, produktion |
| `agent-organizer` | Multi-agent orkestrering, team-assembly, workflow |

### Cloud & Infrastruktur

| Agent | Användning |
|-------|-----------|
| `cloud-architect` | Multi-cloud strategier (AWS/Azure/GCP), skalbarhet, säkerhet |
| `cloud-orchestrator` | AWS/GCP deployment-planering för Node.js/HTML projekt |

### Design & UI

| Agent | Användning |
|-------|-----------|
| `ui-designer` | UI-komponenter, design systems, mockups, accessibility |

### Övrigt

| Agent | Användning |
|-------|-----------|
| `Bash` | Git-operationer, kommandoexekvering, terminal-tasks |
| `claude-code-guide` | Frågor om Claude Code CLI, Agent SDK, Claude API |

**Tips:** Kör flera agenter parallellt för effektivitet när uppgifterna är oberoende.

---

# UTVECKLINGSSTATUS (2026-01-11)

## Vad som är klart

### Dashboard (WHOOP-stil)
- ✅ Tre ringgauger: Belastning, Återhämtning, Sömn
- ✅ COACHING-sektion med AI-insikt
- ✅ Stress & Energi med bågmätare
- ✅ Energibar (85%)
- ✅ Hälsomonitor i 2-kolumnsrutnät (RR, RHR, HRV, SpO2, Temp, Sömn)
- ✅ Aktivitetstidslinje
- ✅ Demo-läge fungerar

### Inställningar & Insikter
- ✅ Redesignad med VitalyCard-komponenter
- ✅ Insikter har "Kommer snart"-vy

### App-ikon
- ✅ Ny sunburst-design i orange/korall-gradient

### Firebase
- ✅ GoogleService-Info.plist tillagd
- ✅ Bundle ID: com.perfectfools.vitaly

## PÅGÅENDE ARBETE - NÄSTA SESSION

### Nya detaljvyer (SKAPADE men behöver läggas till i Xcode)

Filerna finns i `iOSHealth/Features/Dashboard/Views/`:

1. **StrainDetailEnhancedView.swift** - Detaljvy för Belastning
2. **RecoveryDetailEnhancedView.swift** - Detaljvy för Återhämtning
3. **SleepDetailEnhancedView.swift** - Detaljvy för Sömn
4. **MetricDetailSheet.swift** - Modal för hälsometriker

### Login/Intro (UPPDATERADE)
- **LoginView.swift** - Animerad sunburst-logga
- **OnboardingView.swift** - Ingångsanimationer

## NÄSTA STEG

### 1. Lägg till nya filer i Xcode manuellt
Öppna `Vitaly.xcodeproj` i Xcode:
1. Högerklicka på `Features/Dashboard/Views`
2. "Add Files to Vitaly..."
3. Välj de 4 nya filerna

### 2. Fixa SPM-paket
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/Vitaly-*
# Öppna projektet i Xcode och låt det lösa paket
```

### 3. Koppla navigation
Uppdatera DashboardView.swift - gör ringarna tappbara med NavigationLink

## KOMMANDON

```bash
# Bygg
xcodebuild -project Vitaly.xcodeproj -scheme Vitaly -destination 'platform=iOS Simulator,id=A745E301-55E9-46F7-B77A-5B8A8ECC0C5A' build

# Installera och kör
xcrun simctl install A745E301-55E9-46F7-B77A-5B8A8ECC0C5A ~/Library/Developer/Xcode/DerivedData/Vitaly-*/Build/Products/Debug-iphonesimulator/Vitaly.app
xcrun simctl launch A745E301-55E9-46F7-B77A-5B8A8ECC0C5A com.perfectfools.vitaly

# Skärmbild
xcrun simctl io A745E301-55E9-46F7-B77A-5B8A8ECC0C5A screenshot /tmp/screenshot.png
```

## VIKTIGT
- Använd **Vitaly.xcodeproj** (inte iOSHealth.xcodeproj - det är korrupt)
- Simulator ID: A745E301-55E9-46F7-B77A-5B8A8ECC0C5A (iPhone 17 Pro)
