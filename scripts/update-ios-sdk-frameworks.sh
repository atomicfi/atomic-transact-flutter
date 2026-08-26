#!/bin/bash
set -euo pipefail

# Downloads and vendors AtomicSDK XCFrameworks from GitHub releases.
# Reads the version from the example app's Package.resolved (dependabot's source
# of truth) and rewrites the plugin's Package.swift `from:` pin to match.
# Usage: ./scripts/update-ios-sdk-frameworks.sh

REPO="atomicfi/atomic-transact-ios"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
FRAMEWORKS_DIR="${PROJECT_DIR}/ios/frameworks"
VERSION_FILE="${FRAMEWORKS_DIR}/.sdk-version"
PACKAGE_SWIFT="${PROJECT_DIR}/ios/atomic_transact_flutter/Package.swift"
PACKAGE_RESOLVED="${PROJECT_DIR}/example/ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"

# Read version from Package.resolved
if [ ! -f "$PACKAGE_RESOLVED" ]; then
  echo "Error: Package.resolved not found at ${PACKAGE_RESOLVED}" >&2
  exit 1
fi

VERSION=$(python3 -c "
import json, sys
data = json.load(open('${PACKAGE_RESOLVED}'))
for pin in data.get('pins', []):
    if pin.get('identity') == 'atomic-transact-ios':
        print(pin['state']['version'])
        break
else:
    print('Error: atomic-transact-ios pin not found in Package.resolved', file=sys.stderr)
    sys.exit(1)
")

# Rewrite Package.swift `from:` to match Package.resolved
if [ ! -f "$PACKAGE_SWIFT" ]; then
  echo "Error: Package.swift not found at ${PACKAGE_SWIFT}" >&2
  exit 1
fi

python3 -c "
import re
path = '${PACKAGE_SWIFT}'
content = open(path).read()
new_content = re.sub(
    r'(atomic-transact-ios\.git[^)]*?from:\s*\")([^\"]+)(\")',
    r'\g<1>${VERSION}\g<3>',
    content,
    count=1,
)
if new_content == content:
    # Nothing to change; leave the file untouched.
    pass
else:
    open(path, 'w').write(new_content)
"

BASE_URL="https://github.com/${REPO}/releases/download/${VERSION}"

FRAMEWORKS=(
  "AtomicTransact.xcframework.tar.gz"
  "MuppetIOS.xcframework.tar.gz"
  "Uplink.xcframework.tar.gz"
)

echo "Updating iOS SDK to version ${VERSION} (from Package.resolved)..."

# Check if already at this version
if [ -f "$VERSION_FILE" ] && [ "$(cat "$VERSION_FILE")" = "$VERSION" ]; then
  echo "Already at version ${VERSION}. Skipping."
  exit 0
fi

# Create frameworks directory
mkdir -p "$FRAMEWORKS_DIR"

# Clean existing frameworks
echo "Cleaning existing frameworks..."
rm -rf "${FRAMEWORKS_DIR}"/*.xcframework

# Download and extract each framework
for ASSET in "${FRAMEWORKS[@]}"; do
  DOWNLOAD_URL="${BASE_URL}/${ASSET}"
  echo "Downloading ${ASSET}..."

  if ! curl -fSL --retry 3 -o "${FRAMEWORKS_DIR}/${ASSET}" "$DOWNLOAD_URL"; then
    echo "Error: Failed to download ${ASSET} from ${DOWNLOAD_URL}" >&2
    exit 1
  fi

  echo "Extracting ${ASSET}..."
  tar -xzf "${FRAMEWORKS_DIR}/${ASSET}" -C "${FRAMEWORKS_DIR}"

  # Clean up tarball
  rm -f "${FRAMEWORKS_DIR}/${ASSET}"
done

# Move frameworks out of artifacts/ subdirectory if present
if [ -d "${FRAMEWORKS_DIR}/artifacts" ]; then
  mv "${FRAMEWORKS_DIR}"/artifacts/*.xcframework "${FRAMEWORKS_DIR}/"
  rm -rf "${FRAMEWORKS_DIR}/artifacts"
fi

# Write version file
echo "$VERSION" > "$VERSION_FILE"

echo "iOS SDK updated to version ${VERSION} successfully."
