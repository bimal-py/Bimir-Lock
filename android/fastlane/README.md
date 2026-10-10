fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Android

### android deploy

```sh
[bundle exec] fastlane android deploy
```

Upload a prebuilt .aab as a draft release (no build, no listing)

### android download_listing

```sh
[bundle exec] fastlane android download_listing
```

Download the live Play listing (text, graphics, screenshots, changelogs)

### android download_store_details

```sh
[bundle exec] fastlane android download_store_details
```

Download Play Console store settings (support email, phone, website)

### android probe

```sh
[bundle exec] fastlane android probe
```

Print the live Play listing — locales, titles and field lengths

### android images

```sh
[bundle exec] fastlane android images
```

List the live Play graphics for a locale and compare them with disk

### android tracks

```sh
[bundle exec] fastlane android tracks
```

List the Play tracks and the releases in them

### android upload_listing

```sh
[bundle exec] fastlane android upload_listing
```

Upload store-listing text only (no binary, no images, no release notes)

### android upload_changelogs

```sh
[bundle exec] fastlane android upload_changelogs
```

Upload changelogs onto an existing release (no binary, no listing text)

### android upload_images

```sh
[bundle exec] fastlane android upload_images
```

Upload icon, feature graphic and screenshots (no text, no binary)

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
