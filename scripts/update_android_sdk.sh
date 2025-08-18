#!/bin/bash

set -e

GRADLE_FILE="android/build.gradle"
ARTIFACT_NAME="financial.atomic:transact"

# Function to show usage
show_usage() {
    echo "Usage: $0 [--check]"
    echo ""
    echo "Options:"
    echo "  --check    Check latest version without updating"
    echo "  -h, --help Show this help message"
}

# Check if gradle file exists
if [[ ! -f "$GRADLE_FILE" ]]; then
    echo "Error: $GRADLE_FILE not found"
    exit 1
fi

# Function to get latest version from Maven Central
get_latest_version() {
    # Try multiple Maven Central endpoints
    local latest_version=""
    
    # Try the REST API first
    latest_version=$(curl -s "https://repo1.maven.org/maven2/financial/atomic/transact/maven-metadata.xml" | \
        grep '<latest>' | sed 's/.*<latest>//' | sed 's/<\/latest>.*//' 2>/dev/null)
    
    # If that fails, try the search API
    if [[ -z "$latest_version" ]]; then
        latest_version=$(curl -s "https://search.maven.org/solrsearch/select?q=g:financial.atomic+AND+a:transact&rows=1&wt=json" | \
            grep -o '"latestVersion":"[^"]*"' | \
            sed 's/"latestVersion":"//' | \
            sed 's/"//')
    fi
    
    if [[ -z "$latest_version" ]]; then
        echo "❌ Could not find $ARTIFACT_NAME in Maven Central repository" >&2
        echo "Please check manually at: https://central.sonatype.com/artifact/financial.atomic/transact" >&2
        exit 1
    fi
    
    echo "$latest_version"
}

# Function to get current version from build.gradle
get_current_version() {
    current_version=$(grep "implementation \"$ARTIFACT_NAME:" "$GRADLE_FILE" | sed "s/.*$ARTIFACT_NAME://" | sed 's/".*//')
    
    if [[ -z "$current_version" ]]; then
        echo "Error: Could not find $ARTIFACT_NAME dependency in $GRADLE_FILE"
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
echo "📦 Current Android Transact SDK version: $current_version"

# Get latest version
echo "🔍 Fetching latest Android Transact SDK version from Maven Central..."
latest_version=$(get_latest_version)
echo "🚀 Latest Android Transact SDK version: $latest_version"

# Compare versions
if [[ "$current_version" == "$latest_version" ]]; then
    echo "✅ Android Transact SDK is already up to date!"
    exit 0
fi

if [[ "$CHECK_ONLY" == true ]]; then
    echo "📋 Update available: $current_version → $latest_version"
    echo "Run without --check flag to update"
    exit 0
fi

# Update the gradle file
echo "🔄 Updating Android Transact SDK from $current_version to $latest_version..."

# Create backup
cp "$GRADLE_FILE" "$GRADLE_FILE.bak"

# Update the dependency line
sed -i.tmp "s/implementation \"$ARTIFACT_NAME:[^\"]*\"/implementation \"$ARTIFACT_NAME:$latest_version\"/" "$GRADLE_FILE"
rm "$GRADLE_FILE.tmp"

# Verify the update
new_version=$(get_current_version)
if [[ "$new_version" == "$latest_version" ]]; then
    rm "$GRADLE_FILE.bak"
    echo "✅ Successfully updated Android Transact SDK to $latest_version"
    echo "📝 Updated file: $GRADLE_FILE"
else
    # Restore backup if update failed
    mv "$GRADLE_FILE.bak" "$GRADLE_FILE"
    echo "❌ Failed to update Android Transact SDK dependency"
    exit 1
fi