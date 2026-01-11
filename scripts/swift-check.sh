#!/bin/bash
# swift-check.sh - Snabb syntax-kontroll för Swift-filer
# Körs automatiskt efter varje redigering via Claude Code hooks

FILE_PATH="$1"
PROJECT_DIR="/Users/tonsaj/Workspace/iOSHealth"
PROJECT="$PROJECT_DIR/Vitaly.xcodeproj"

# Om ingen fil angavs, avsluta tyst
if [ -z "$FILE_PATH" ]; then
    exit 0
fi

# Kontrollera att det är en Swift-fil
if [[ ! "$FILE_PATH" =~ \.swift$ ]]; then
    exit 0
fi

# Snabb syntax-kontroll med swiftc
echo "Kontrollerar syntax: $(basename "$FILE_PATH")"

# Använd swift -parse för snabb syntax-check (utan full kompilering)
ERRORS=$(swiftc -parse "$FILE_PATH" 2>&1)

if [ $? -ne 0 ]; then
    echo "Syntaxfel i $FILE_PATH:"
    echo "$ERRORS" | head -10
    exit 1
fi

echo "OK"
exit 0
