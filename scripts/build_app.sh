#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: scripts/build_app.sh [--install] [--help]

Builds the Actual Wi-Fi Bars macOS app bundle.

Options:
  --install    Copy the built app to /Applications after building
  --help       Show this help message

Environment:
  CONFIGURATION=debug|release    Build configuration (default: release)
EOF
}

SCRIPT_IS_SOURCED=0
if [[ -n "${BASH_VERSION:-}" && "${BASH_SOURCE[0]}" != "$0" ]]; then
    SCRIPT_IS_SOURCED=1
elif [[ -n "${ZSH_VERSION:-}" && "${ZSH_EVAL_CONTEXT:-}" == *:file* ]]; then
    SCRIPT_IS_SOURCED=1
fi

if [[ "$SCRIPT_IS_SOURCED" == "1" ]]; then
    usage
    echo
    echo "This script should be executed, not sourced. Run: ./build_app.sh"
    return 2
fi

case "${1:-}" in
    ""|"--install")
        ;;
    "--help"|"-h")
        usage
        exit 0
        ;;
    *)
        usage >&2
        echo >&2
        echo "Unknown option: $1" >&2
        exit 2
        ;;
esac

SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
ROOT_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"
CONFIGURATION="${CONFIGURATION:-release}"
APP_NAME="Actual Wi-Fi Bars"
BUNDLE_PATH="$ROOT_DIR/.build/$CONFIGURATION/$APP_NAME.app"
CONTENTS_PATH="$BUNDLE_PATH/Contents"
MACOS_PATH="$CONTENTS_PATH/MacOS"
RESOURCES_PATH="$CONTENTS_PATH/Resources"
ICONSET_PATH="$ROOT_DIR/.build/AppIcon.iconset"

swift build -c "$CONFIGURATION"

rm -rf "$BUNDLE_PATH" "$ICONSET_PATH"
mkdir -p "$MACOS_PATH" "$RESOURCES_PATH" "$ICONSET_PATH"

cp "$ROOT_DIR/.build/$CONFIGURATION/ActualWifiBars" "$MACOS_PATH/ActualWifiBars"
cp "$ROOT_DIR/Packaging/Info.plist" "$CONTENTS_PATH/Info.plist"

swift "$ROOT_DIR/scripts/generate_app_icon.swift" "$ICONSET_PATH"
iconutil -c icns "$ICONSET_PATH" -o "$RESOURCES_PATH/AppIcon.icns"

chmod +x "$MACOS_PATH/ActualWifiBars"

if [[ "${1:-}" == "--install" ]]; then
    INSTALL_PATH="/Applications/$APP_NAME.app"
    if ditto "$BUNDLE_PATH" "$INSTALL_PATH"; then
        echo "Installed $INSTALL_PATH"
    else
        echo "Could not install to $INSTALL_PATH." >&2
        echo "The app was still built at $BUNDLE_PATH." >&2
        echo "Try dragging it into Applications in Finder." >&2
        exit 1
    fi
else
    echo "Built $BUNDLE_PATH"
fi
