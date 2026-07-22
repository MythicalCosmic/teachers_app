# StarForge EDU Staff

StarForge EDU Staff is the mobile workspace for operational education staff. It
ships as a Flutter app in [`app/`](app/) and intentionally excludes CEO,
manager, parent, and student application roles.

Permitted roles:

- Teacher
- Assistant
- Methodist / academic quality
- Reception / admissions
- Auditor

The shipped entry point uses the authenticated production API adapter. A
deterministic demo repository remains for isolated development and tests, but
production routes must never present demo records as server data. Modules whose
server contract is not implemented are routed to an honest server-backed hub or
availability state.

## Run locally

Flutter 3.44.6 or newer is recommended.

```powershell
cd app
flutter pub get
flutter analyze
flutter test
flutter run
```

See [the product and permission specification](docs/STAFF_APP_PRODUCT_SPEC.md)
for scope and security rules. A signed iPhone build is produced by the manual
GitHub Actions workflow documented in [the IPA signing guide](docs/IOS_SIGNING.md).
For free Apple ID testing, the root-level
[Codemagic workflow](docs/CODEMAGIC_IOS.md) produces an unsigned release IPA
that can be signed for a connected iPhone with 3uTools.
