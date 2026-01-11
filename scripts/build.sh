#!/bin/bash
# build.sh - Bygger Vitaly-appen med paketupplösning via Xcode
# Användning: ./scripts/build.sh [--run] [--screenshot]

set -e

PROJECT_DIR="/Users/tonsaj/Workspace/iOSHealth"
PROJECT="$PROJECT_DIR/Vitaly.xcodeproj"
SCHEME="Vitaly"
SIMULATOR_ID="${SIMULATOR_ID:-A745E301-55E9-46F7-B77A-5B8A8ECC0C5A}"
BUNDLE_ID="com.perfectfools.vitaly"
BUILD_LOG="/tmp/xcode-build.log"

# Färger för output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Vitaly Build Script${NC}"
echo "================================"

# Funktion för att öppna Xcode och vänta på paketupplösning
resolve_packages() {
    echo -e "${YELLOW}Löser paketberoenden via Xcode...${NC}"

    # Öppna projektet i Xcode
    open "$PROJECT"

    # Vänta på att Xcode ska starta och lösa paket
    echo "Väntar på Xcode (30 sek)..."
    sleep 30

    # Kör resolvePackageDependencies
    xcodebuild -project "$PROJECT" -resolvePackageDependencies 2>&1 | tail -5
}

# Funktion för att bygga
build() {
    echo -e "${YELLOW}Bygger projekt...${NC}"

    xcodebuild -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
        -configuration Debug \
        build 2>&1 | tee "$BUILD_LOG"

    if grep -q "BUILD SUCCEEDED" "$BUILD_LOG"; then
        echo -e "${GREEN}Build lyckades!${NC}"
        return 0
    else
        echo -e "${RED}Build misslyckades.${NC}"
        echo "Fel:"
        grep "error:" "$BUILD_LOG" | head -10
        return 1
    fi
}

# Funktion för att köra appen
run_app() {
    echo -e "${YELLOW}Startar app på simulator...${NC}"

    # Hitta app-bundle
    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/Vitaly-*/Build/Products/Debug-iphonesimulator -name "Vitaly.app" 2>/dev/null | head -1)

    if [ -z "$APP_PATH" ]; then
        echo -e "${RED}Kunde inte hitta Vitaly.app${NC}"
        return 1
    fi

    # Starta simulator
    xcrun simctl boot "$SIMULATOR_ID" 2>/dev/null || true
    open -a Simulator

    # Installera och starta
    xcrun simctl install "$SIMULATOR_ID" "$APP_PATH"
    xcrun simctl launch "$SIMULATOR_ID" "$BUNDLE_ID"

    echo -e "${GREEN}App startad!${NC}"
}

# Funktion för skärmdump
take_screenshot() {
    SCREENSHOT_PATH="${1:-/tmp/vitaly-screenshot.png}"
    echo -e "${YELLOW}Tar skärmdump...${NC}"

    sleep 2  # Vänta på att UI ska rendera
    xcrun simctl io "$SIMULATOR_ID" screenshot "$SCREENSHOT_PATH"

    echo -e "${GREEN}Skärmdump sparad: $SCREENSHOT_PATH${NC}"
}

# Huvudlogik
RUN_APP=false
TAKE_SCREENSHOT=false

for arg in "$@"; do
    case $arg in
        --run)
            RUN_APP=true
            ;;
        --screenshot)
            TAKE_SCREENSHOT=true
            ;;
        --resolve)
            resolve_packages
            exit 0
            ;;
        --help)
            echo "Användning: ./scripts/build.sh [options]"
            echo ""
            echo "Options:"
            echo "  --run         Kör appen efter build"
            echo "  --screenshot  Ta skärmdump efter körning"
            echo "  --resolve     Löser bara paketberoenden"
            echo "  --help        Visa denna hjälp"
            exit 0
            ;;
    esac
done

# Kör build
if build; then
    if $RUN_APP; then
        run_app

        if $TAKE_SCREENSHOT; then
            take_screenshot
        fi
    fi
else
    echo -e "${RED}Build misslyckades. Försök med: ./scripts/build.sh --resolve${NC}"
    exit 1
fi
