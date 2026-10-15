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

Releases are tagged with `cog`. A tag builds Android, Linux, Windows, and
web artifacts through GitHub Actions and syncs them back to GitLab
releases. The landing page in `landing/` deploys to GitLab Pages.

## License

AGPL-3.0
