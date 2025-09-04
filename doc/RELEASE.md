# Release Guide

This document describes how to create releases for the Atomic Transact Flutter plugin.

## Release Process

1. **Prepare the release**

   - Ensure all changes are committed and merged to master
   - Run tests to verify everything works
   - Update documentation if needed

2. **Update SDK dependencies (if needed)**

   **Option A: Automated (Recommended)**

   - Trigger the "update sdk's" GitHub Actions workflow
   - Review and merge the created pull requests

   **Option B: Manual**

   ```bash
   # Update iOS SDK
   ./update_atomic_sdk.sh --check    # Check for updates
   ./update_atomic_sdk.sh            # Apply updates if available

   # Update Android SDK
   ./update_android_sdk.sh --check   # Check for updates
   ./update_android_sdk.sh           # Apply updates if available
   ```

3. **Create a GitHub Release**

   - Go to the Releases page on GitHub
   - Click "Create a new release"
   - Create a new tag following the format `vX.Y.Z` (e.g., `v3.13.4`)
   - Add release notes describing the changes
   - Click "Publish release"

4. **Automated Publishing**
   - The publish workflow will automatically trigger
   - It will update the version in `pubspec.yaml` and `ios/atomic_transact_flutter.podspec` to match the release tag
   - The package will be automatically published to pub.dev

**Note:** The automated workflow handles version bumping and publishing, so manual version updates and tagging are no longer required.

## Automated Workflows

### SDK Update Workflow

The repository includes an automated workflow (`.github/workflows/update_sdks.yml`) that can be manually triggered to:

- Check for the latest iOS and Android SDK versions
- Create separate branches for each SDK update
- Automatically create pull requests with the updates

**To trigger SDK updates:**

1. Go to the Actions tab in GitHub
2. Select "update sdk's" workflow
3. Click "Run workflow"

The workflow will:

- Run on both Ubuntu (for Android) and macOS (for iOS)
- Use the update scripts to check for and apply updates
- Create feature branches named `update_android_sdk_X.Y.Z` and `update_ios_sdk_X.Y.Z`
- Open pull requests against the master branch

### Automated Publishing

The publish workflow (`.github/workflows/publish.yml`) automatically triggers when a GitHub release is published and:

- Sets the version from the release tag
- Installs Flutter and dependencies
- Publishes the package to pub.dev
