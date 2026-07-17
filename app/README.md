# StarForge EDU Staff Flutter app

The application is an Uzbek-first Flutter client for teachers, assistants,
methodists, reception staff, and auditors. Its custom design system lives in
`lib/theme` and `lib/widgets`; persisted domain state and the replaceable local
repository live in `lib/app` and `lib/data`.

## Development gates

```powershell
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

The opt-in iPhone-sized visual catalogue is intentionally separate from the
cross-platform test suite:

```powershell
flutter test tool/visual_catalog_test.dart --update-goldens
```

The demo credentials are documented in the repository root README. Do not add
CEO, manager, parent, or student roles to this client.

Release IPA signing is intentionally performed on a macOS GitHub runner. See
`../docs/IOS_SIGNING.md` for the required encrypted repository secrets and the
installable-development build flow.
