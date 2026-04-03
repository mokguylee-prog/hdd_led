#!/bin/zsh
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
APP="$SCRIPT_DIR/Noti HDD.app"
EXECUTABLE_NAME="Noti HDD"

if [[ ! -d "$APP" ]]; then
    echo "✗ App not found at: $APP"
    echo "  Run ./buildrun.sh first."
    exit 1
fi

pkill -x "$EXECUTABLE_NAME" 2>/dev/null && sleep 0.3 || true
open "$APP"
