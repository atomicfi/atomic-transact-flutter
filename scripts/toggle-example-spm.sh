#!/bin/bash
set -euo pipefail

# Toggles the example app between Swift Package Manager and CocoaPods.
# Detects the current mode by checking for example/ios/Podfile.
# Usage: ./scripts/toggle-example-spm.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
EXAMPLE_IOS_DIR="${PROJECT_DIR}/example/ios"

if [ ! -d "$EXAMPLE_IOS_DIR" ]; then
  echo "Error: ${EXAMPLE_IOS_DIR} not found" >&2
  exit 1
fi

if [ -f "${EXAMPLE_IOS_DIR}/Podfile" ]; then
  echo "Example app is currently using CocoaPods. Switching to SPM..."

  flutter config --enable-swift-package-manager

  cd "$EXAMPLE_IOS_DIR"

  if command -v pod >/dev/null 2>&1; then
    echo "Running pod deintegrate..."
    pod deintegrate || true
  else
    echo "CocoaPods not installed; skipping pod deintegrate."
  fi

  echo "Removing Podfile and Podfile.lock..."
  rm -f Podfile Podfile.lock

  echo "Removing Pods xcconfig includes..."
  if [ -f Flutter/Debug.xcconfig ]; then
    sed -i '' '/Pods-Runner.debug.xcconfig/d' Flutter/Debug.xcconfig
  fi
  if [ -f Flutter/Release.xcconfig ]; then
    sed -i '' '/Pods-Runner.release.xcconfig/d' Flutter/Release.xcconfig
  fi

  WORKSPACE_FILE="Runner.xcworkspace/contents.xcworkspacedata"
  if [ -f "$WORKSPACE_FILE" ]; then
    echo "Removing Pods reference from workspace..."
    cat > "$WORKSPACE_FILE" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "group:Runner.xcodeproj">
   </FileRef>
</Workspace>
EOF
  fi

  echo
  echo "Done. Example app now uses Swift Package Manager."
else
  echo "Example app is currently using SPM. Switching to CocoaPods..."

  flutter config --no-enable-swift-package-manager

  echo
  echo "Done. SPM is disabled globally."
fi

echo
echo "Running 'flutter build ios' in example..."
cd "${PROJECT_DIR}/example"
flutter build ios --no-codesign
