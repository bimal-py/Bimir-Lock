fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios download_listing

```sh
[bundle exec] fastlane ios download_listing
```

Download the live App Store listing (metadata + screenshots)

### ios ensure_edit_version

```sh
[bundle exec] fastlane ios ensure_edit_version
```

Create an editable App Store version if there is not one already

### ios locales

```sh
[bundle exec] fastlane ios locales
```

List the App Store locales this app accepts, vs what is on disk

### ios upload_listing

```sh
[bundle exec] fastlane ios upload_listing
```

Upload the App Store listing (no binary)

### ios upload_screenshots

```sh
[bundle exec] fastlane ios upload_screenshots
```

Upload App Store screenshots only (no text, no binary)

### ios probe

```sh
[bundle exec] fastlane ios probe
```

Check App Store Connect credentials and show the app's versions

### ios upload_release_notes

```sh
[bundle exec] fastlane ios upload_release_notes
```

Upload What's New (release notes) only - no other metadata, no binary

### ios probe_live

```sh
[bundle exec] fastlane ios probe_live
```

Print the LIVE App Store version's copy (read-only)

### ios pull_live_copy

```sh
[bundle exec] fastlane ios pull_live_copy
```

Save the LIVE version's promo text and release notes into metadata/

### ios upload_version_copy

```sh
[bundle exec] fastlane ios upload_version_copy
```

Upload promotional text + What's New to the editable version (no name/subtitle replay)

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
