#!/bin/bash

set -e

PODSPEC_FILE="ios/atomic_transact_flutter.podspec"
POD_NAME="AtomicSDK"

# Function to show usage
show_usage() {
    echo "Usage: $0 [--check]"
    echo ""
    echo "Options:"
    echo "  --check    Check latest version without updating"
    echo "  -h, --help Show this help message"
}

# Check if podspec file exists
if [[ ! -f "$PODSPEC_FILE" ]]; then
    echo "Error: $PODSPEC_FILE not found"
    exit 1
fi

# Check if pod command is available
if ! command -v pod &> /dev/null; then
    echo "Error: CocoaPods 'pod' command not found. Please install CocoaPods first."
    echo "Install with: sudo gem install cocoapods"
    exit 1
fi

# Function to get latest version from CocoaPods
get_latest_version() {
    # Use pod search to get the latest version
    local latest_version=$(pod search $POD_NAME --simple 2>/dev/null | grep "$POD_NAME " | head -1 | sed 's/.*(//' | sed 's/)//')
    
    if [[ -z "$latest_version" ]]; then
        echo "❌ Could not find $POD_NAME in CocoaPods repository" >&2
        echo "Please check manually at: https://cocoapods.org/pods/$POD_NAME" >&2
        exit 1
    fi
    
    echo "$latest_version"
}

# Function to get current version from podspec
get_current_version() {
    current_version=$(grep "s\.dependency '$POD_NAME'" "$PODSPEC_FILE" | sed "s/.*'$POD_NAME', '//" | sed "s/'.*//")
    
    if [[ -z "$current_version" ]]; then
        echo "Error: Could not find $POD_NAME dependency in $PODSPEC_FILE"
        exit 1
    fi
    
    echo "$current_version"
}

# Parse command line arguments
CHECK_ONLY=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --check)
            CHECK_ONLY=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Get current version
current_version=$(get_current_version)
echo "📦 Current $POD_NAME version: $current_version"

# Get latest version
echo "🔍 Fetching latest $POD_NAME version from CocoaPods..."
latest_version=$(get_latest_version)
echo "🚀 Latest $POD_NAME version: $latest_version"

# Compare versions
if [[ "$current_version" == "$latest_version" ]]; then
    echo "✅ $POD_NAME is already up to date!"
    exit 0
fi

if [[ "$CHECK_ONLY" == true ]]; then
    echo "📋 Update available: $current_version → $latest_version"
    echo "Run without --check flag to update"
    exit 0
fi

# Update the podspec file
echo "🔄 Updating $POD_NAME from $current_version to $latest_version..."

# Create backup
cp "$PODSPEC_FILE" "$PODSPEC_FILE.bak"

# Update the dependency line
sed -i.tmp "s/s\.dependency '$POD_NAME', '[^']*'/s.dependency '$POD_NAME', '$latest_version'/" "$PODSPEC_FILE"
rm "$PODSPEC_FILE.tmp"

# Verify the update
new_version=$(get_current_version)
if [[ "$new_version" == "$latest_version" ]]; then
    rm "$PODSPEC_FILE.bak"
    echo "✅ Successfully updated $POD_NAME to $latest_version"
    echo "📝 Updated file: $PODSPEC_FILE"
else
    # Restore backup if update failed
    mv "$PODSPEC_FILE.bak" "$PODSPEC_FILE"
    echo "❌ Failed to update $POD_NAME dependency"
    exit 1
fi