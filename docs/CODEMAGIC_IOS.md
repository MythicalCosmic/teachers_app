# Codemagic iPhone build

The root [`codemagic.yaml`](../codemagic.yaml) builds the Flutter project from
`app/` in Flutter **release mode** and publishes a Development-signed IPA for
direct installation on a registered iPhone. The signing type does not change
the Flutter build mode: the workflow explicitly runs `flutter build ipa
--release`.

## One-time signing setup

In Codemagic, open **Team settings → codemagic.yaml settings → Code signing
identities**.

1. Add, generate, or fetch an **Apple Development** certificate.
2. Add or fetch a **Development provisioning profile** for
   `uz.starforge.starforgeEdu`.
3. Confirm the target iPhone UDID is included in that profile.

The workflow selects the matching certificate and profile through
`distribution_type: development` and the bundle identifier. No certificate,
profile, password, or API key belongs in this repository.

## Start the build

1. In Codemagic, add or rescan the repository and select `codemagic.yaml` from
   the repository root (`.`).
2. Choose **StarForge Staff - iPhone Release IPA**.
3. Start a new build from `main`.
4. Download `StarForge-Staff-release.ipa` from **Artifacts**.

The workflow resolves dependencies, checks formatting, analyzes and tests the
app, applies the signing profile, builds the release IPA, and then validates
the exported bundle ID, embedded provisioning profile, registered-device list,
container layout, and code signature.
