# floof

A video client for e926.net and other e621-compatible booru hosts.

## Features

- Home feed driven by a local taste engine. It scores tags from how you
  actually watch and adjusts your feed over time. Nothing leaves the device.
- Search with tag autocomplete.
- Swipe-style video viewing with autoplay.
- History and timeline of what you watched and marked done.
- Done lets you attach a photo when you finish a video, or skip it.
- Profiles so different people (or moods) keep separate feeds.
- Guest e926 account by default, login with API key, or point it at e621
  or any compatible host.
- Light, dark, and OLED themes, four languages.
- In-app update checks against GitLab releases.

## Install

- Android APK/AAB, Linux (tar.gz, deb, rpm, AppImage), macOS, and Windows
  builds are attached to each release.
- Flatpak (x86_64 and aarch64): add the repo once, then install and update
  like any remote:

  ```
  flatpak remote-add --if-not-exists floof https://httpanimations.gitlab.io/floof/flatpak/floof.flatpakrepo
  flatpak install floof gitlab.httpanimations.floof
  ```

  Or install directly from the flatpakref:

  ```
  flatpak install https://httpanimations.gitlab.io/floof/flatpak/floof.flatpakref
  ```

  The signed repo lives at `https://httpanimations.gitlab.io/floof/flatpak`,
  and releases also ship `floof.flatpakref`, standalone `.flatpak` bundles,
  and a tarball of the whole repo.
- iOS: builds are unsigned IPAs meant for sideloading. In AltStore or
  SideStore, go to Sources, tap +, and add

  `https://gitlab.com/HttpAnimations/floof/-/raw/main/repos/altstore.json`

  floof then appears in the store and updates itself with each release.
  Alternatively grab `floof-ios.ipa` from the release and sign it yourself.

## Build

```
flutter pub get
flutter gen-l10n
flutter run
```

## Test

```
flutter analyze
flutter test --coverage
```

Tests are expected to cover every line.

## Release

Releases are tagged with `cog`. A tag builds Android, Linux, Windows,
macOS, iOS, and web artifacts through GitHub Actions and syncs them back
to GitLab releases. The Flatpak repo and the AltStore source are updated
in the same run. The landing page in `landing/` deploys to GitLab Pages.

## License

AGPL-3.0
