# Codemagic iPhone build for 3uTools

The root [`codemagic.yaml`](../codemagic.yaml) builds the Flutter project from
`app/` in Flutter **release mode** without Apple code signing. It packages the
result in the `Payload/Runner.app` IPA structure required by signing tools.

This workflow intentionally requires no paid Apple Developer membership,
certificate, or Codemagic provisioning profile. Its IPA is not installable
until it is signed for a specific iPhone.

## Build the unsigned release

1. In Codemagic, add or rescan the repository and select `codemagic.yaml` from
   the repository root (`.`).
2. Choose **StarForge Staff - Unsigned Release for 3uTools**.
3. Start a new build from `main`.
4. Download `StarForge-Staff-unsigned-release.ipa` from **Artifacts**.

The workflow resolves dependencies, checks formatting, analyzes and tests the
app, compiles the ARM64 iPhone release, creates both an unsigned IPA and a
`Runner.app` ZIP, and verifies their bundle identifier and container layout.

## Sign and install with a free Apple ID

1. Connect the target iPhone to 3uTools so its UDID is selected correctly.
2. Open **Toolbox → IPA Signature**.
3. Choose **Sign with Apple ID**, add the Apple ID, and select the connected
   device.
4. Add `StarForge-Staff-unsigned-release.ipa` and start signing.
5. Install the newly signed IPA from **Open Signed IPA Location**.

A free Apple ID signature is device-bound and normally valid for seven days,
after which the IPA must be signed and installed again. Never commit Apple ID
credentials to this repository or add them to Codemagic.
