#!/bin/bash

set -e

PUBSPEC_FILE="pubspec.yaml"
PODSPEC_FILE="ios/atomic_transact_flutter.podspec"
CHANGELOG_FILE="CHANGELOG.md"

NEW_VERSION=""

# Function to show usage
show_usage() {
    echo "Usage: $0 --version VERSION"
    echo ""
    echo "Options:"
    echo "  --version VERSION Set specific version (e.g., --version 1.2.3)"
    echo "  -h, --help        Show this help message"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --version)
            if [[ -n "$2" ]]; then
                NEW_VERSION="$2"
                shift 2
            else
                echo "Error: --version requires a value"
                show_usage
                exit 1
            fi
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

# Check if version was provided
if [[ -z "$NEW_VERSION" ]]; then
    echo "Error: Version is required"
    show_usage
    exit 1
fi

# Check if files exist
if [[ ! -f "$PUBSPEC_FILE" ]]; then
    echo "Error: $PUBSPEC_FILE not found"
    exit 1
fi

if [[ ! -f "$PODSPEC_FILE" ]]; then
    echo "Error: $PODSPEC_FILE not found"
    exit 1
fi

if [[ ! -f "$CHANGELOG_FILE" ]]; then
    echo "Error: $CHANGELOG_FILE not found"
    exit 1
fi

# Extract current version from pubspec.yaml
current_version=$(grep "^version:" "$PUBSPEC_FILE" | sed 's/version: //')

if [[ -z "$current_version" ]]; then
    echo "Error: Could not find version in $PUBSPEC_FILE"
    exit 1
fi

echo "Current version: $current_version"

# Validate new version format
if [[ ! "$NEW_VERSION" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
    echo "Error: Version format should be x.y.z (found: $NEW_VERSION)"
    exit 1
fi

new_version="$NEW_VERSION"
echo "Setting version to: $new_version"

# Function to update changelog
update_changelog() {
    local version=$1
    local github_url="https://github.com/atomicfi/atomic-transact-flutter/releases/tag/${version}"
    
    # Create a temporary file with the new changelog entry
    local temp_file=$(mktemp)
    
    # Add the new version entry at the top
    echo "## $version" > "$temp_file"
    echo "" >> "$temp_file"
    echo "- [Release Notes]($github_url)" >> "$temp_file"
    echo "" >> "$temp_file"
    
    # Append the existing changelog content
    cat "$CHANGELOG_FILE" >> "$temp_file"
    
    # Replace the original changelog with the updated one
    mv "$temp_file" "$CHANGELOG_FILE"
}

# Update pubspec.yaml
sed -i.bak "s/^version: .*/version: $new_version/" "$PUBSPEC_FILE"
rm "$PUBSPEC_FILE.bak"

# Update podspec file
sed -i.bak "s/s\.version *= *'[^']*'/s.version          = '$new_version'/" "$PODSPEC_FILE"
rm "$PODSPEC_FILE.bak"

# Update changelog
update_changelog "$new_version"

echo "✅ Successfully updated version to $new_version in all files"
echo "📝 Updated files:"
echo "  - $PUBSPEC_FILE"
echo "  - $PODSPEC_FILE"
echo "  - $CHANGELOG_FILE"
