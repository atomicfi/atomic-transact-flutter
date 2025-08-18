# Release Guide

This document describes how to create releases for the Atomic Transact Flutter plugin.

## AtomicSDK Dependency Update Script

The `update_atomic_sdk.sh` script automatically updates the AtomicSDK dependency to the latest version available in CocoaPods.

### Usage

```bash
./update_atomic_sdk.sh [--check]
```

### Options

| Option | Description |
|--------|-------------|
| `--check` | Check for updates without applying them |
| `--help` | Show usage information |

If no option is specified, the script will update to the latest version.

### Examples

```bash
# Check for AtomicSDK updates without applying them
./update_atomic_sdk.sh --check

# Update AtomicSDK to the latest version
./update_atomic_sdk.sh

# Show help
./update_atomic_sdk.sh --help
```

### What the script does

1. Reads the current AtomicSDK version from `ios/atomic_transact_flutter.podspec`
2. Fetches the latest version from CocoaPods using `pod search`
3. Compares the versions and shows the status
4. If updating, modifies the `s.dependency 'AtomicSDK'` line in the podspec
5. Creates a backup before making changes
6. Provides confirmation of the update

### Example output

```bash
$ ./update_atomic_sdk.sh --check
📦 Current AtomicSDK version: 3.20.0
🔍 Fetching latest AtomicSDK version from CocoaPods...
🚀 Latest AtomicSDK version: 3.20.5
📋 Update available: 3.20.0 → 3.20.5
Run without --check flag to update

$ ./update_atomic_sdk.sh
📦 Current AtomicSDK version: 3.20.0
🔍 Fetching latest AtomicSDK version from CocoaPods...
🚀 Latest AtomicSDK version: 3.20.5
🔄 Updating AtomicSDK from 3.20.0 to 3.20.5...
✅ Successfully updated AtomicSDK to 3.20.5
📝 Updated file: ios/atomic_transact_flutter.podspec
```

### Requirements

- CocoaPods must be installed (`gem install cocoapods`)
- Network connection to fetch the latest version information

### Error handling

The script includes error checking for:
- Missing `ios/atomic_transact_flutter.podspec` file
- Missing CocoaPods installation
- Unable to find AtomicSDK in CocoaPods repository
- Update failures (with automatic backup restoration)

## Android SDK Dependency Update Script

The `update_android_sdk.sh` script automatically updates the Android Transact SDK dependency to the latest version available in Maven Central.

### Usage

```bash
./update_android_sdk.sh [--check]
```

### Options

| Option | Description |
|--------|-------------|
| `--check` | Check for updates without applying them |
| `--help` | Show usage information |

If no option is specified, the script will update to the latest version.

### Examples

```bash
# Check for Android SDK updates without applying them
./update_android_sdk.sh --check

# Update Android SDK to the latest version
./update_android_sdk.sh

# Show help
./update_android_sdk.sh --help
```

### What the script does

1. Reads the current Android SDK version from `android/build.gradle`
2. Fetches the latest version from Maven Central using the REST API
3. Compares the versions and shows the status
4. If updating, modifies the `financial.atomic:transact` dependency line in build.gradle
5. Creates a backup before making changes
6. Provides confirmation of the update

### Example output

```bash
$ ./update_android_sdk.sh --check
📦 Current Android Transact SDK version: 3.11.3
🔍 Fetching latest Android Transact SDK version from Maven Central...
🚀 Latest Android Transact SDK version: 3.11.4
📋 Update available: 3.11.3 → 3.11.4
Run without --check flag to update

$ ./update_android_sdk.sh
📦 Current Android Transact SDK version: 3.11.3
🔍 Fetching latest Android Transact SDK version from Maven Central...
🚀 Latest Android Transact SDK version: 3.11.4
🔄 Updating Android Transact SDK from 3.11.3 to 3.11.4...
✅ Successfully updated Android Transact SDK to 3.11.4
📝 Updated file: android/build.gradle
```

### Requirements

- Network connection to fetch the latest version information from Maven Central
- `curl` command available (standard on most systems)

### Error handling

The script includes error checking for:
- Missing `android/build.gradle` file
- Unable to find the Android Transact SDK in Maven Central repository
- Update failures (with automatic backup restoration)

## Version Bumping Script

The `bump_version.sh` script automatically updates version numbers in both `pubspec.yaml` and `ios/atomic_transact_flutter.podspec` files to keep them in sync.

### Usage

```bash
./bump_version.sh [--major|--minor|--patch]
```

### Options

| Option | Description | Example |
|--------|-------------|---------|
| `--patch` | Bump patch version (x.y.z → x.y.(z+1)) | `3.13.3` → `3.13.4` |
| `--minor` | Bump minor version (x.y.z → x.(y+1).0) | `3.13.3` → `3.14.0` |
| `--major` | Bump major version (x.y.z → (x+1).0.0) | `3.13.3` → `4.0.0` |
| `--help` | Show usage information | |

If no option is specified, the script defaults to bumping the patch version.

### Examples

```bash
# Bump patch version (default behavior)
./bump_version.sh
# 3.13.3 → 3.13.4

# Bump minor version
./bump_version.sh --minor
# 3.13.3 → 3.14.0

# Bump major version
./bump_version.sh --major
# 3.13.3 → 4.0.0

# Show help
./bump_version.sh --help
```

### What the script does

1. Reads the current version from `pubspec.yaml`
2. Validates the version format (x.y.z)
3. Increments the appropriate version component based on the option
4. Updates the version in `pubspec.yaml`
5. Updates the `s.version` field in `ios/atomic_transact_flutter.podspec`
6. Provides confirmation of the changes made

### Error handling

The script includes error checking for:
- Missing `pubspec.yaml` or `atomic_transact_flutter.podspec` files
- Invalid version format in `pubspec.yaml`
- Unknown command line options

## Release Process

1. **Prepare the release**
   - Ensure all changes are committed
   - Run tests to verify everything works
   - Update documentation if needed

2. **Update SDK dependencies (if needed)**
   ```bash
   # Update iOS SDK
   ./update_atomic_sdk.sh --check    # Check for updates
   ./update_atomic_sdk.sh            # Apply updates if available

   # Update Android SDK
   ./update_android_sdk.sh --check   # Check for updates
   ./update_android_sdk.sh           # Apply updates if available
   ```

3. **Bump the version**
   ```bash
   ./bump_version.sh --patch  # or --minor or --major as appropriate
   ```

4. **Commit the version changes**
   ```bash
   git add pubspec.yaml ios/atomic_transact_flutter.podspec android/build.gradle
   git commit -m "chore: bump version to X.Y.Z"
   ```

5. **Create and push a tag**
   ```bash
   git tag vX.Y.Z
   git push origin vX.Y.Z
   ```

6. **Publish the release**
   - Follow platform-specific publishing guidelines
   - Update release notes
   - Announce the release

## Version Guidelines

Follow [Semantic Versioning](https://semver.org/):

- **MAJOR** version: incompatible API changes
- **MINOR** version: backwards-compatible functionality additions
- **PATCH** version: backwards-compatible bug fixes