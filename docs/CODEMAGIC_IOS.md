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
2. Make sure the repository webhook is active in Codemagic.
3. Push to `main`; **StarForge Staff - Unsigned Release for 3uTools** starts
   automatically. You can still start the same workflow manually from `main`
   if webhooks are disabled.
4. Open the completed build's **Artifacts** and use
   `StarForge-Staff-unsigned-release.ipa`.

The workflow resolves dependencies, checks formatting, analyzes and tests the
app, compiles the ARM64 iPhone release, creates both an unsigned IPA and a
`Runner.app` ZIP, and verifies their bundle identifier and container layout.
Both files are written directly to Codemagic's `$CM_EXPORT_DIR`; the workflow
fails if either artifact is missing or empty.

## Push-notification configuration

The unsigned workflow can compile the Firebase client configuration, but it
cannot grant Apple's Push Notifications entitlement. In Codemagic, first
create an application variable group named `firebase_credentials`, then
uncomment that group under `environment` in `codemagic.yaml`. Put **one**
secret variable named `FIREBASE_IOS_CONFIG_BASE64` in that group. Its value is
the base64 encoding of the real `GoogleService-Info.plist` for bundle identifier
`uz.starforge.starforgeEdu`. The workflow validates the bundle identifier and
passes the values to Flutter as compile-time Dart defines. As an alternative,
put all of these secure variables in the same imported group:

- `FIREBASE_API_KEY`
- `FIREBASE_APP_ID`
- `FIREBASE_MESSAGING_SENDER_ID`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_STORAGE_BUCKET` (optional)
- `FIREBASE_IOS_BUNDLE_ID` (defaults to the app bundle identifier)

A partial configuration deliberately fails the build; no configuration keeps
the app installable with push reported as unavailable.

Real background push also requires the backend deployment to mount a Firebase
Admin service-account JSON, set `FCM_CREDENTIALS_FILE` to that mounted path,
and enable `PUSH_NOTIFICATIONS_ENABLED`. Never place either Firebase file in
Git.

Most importantly, an unsigned IPA re-signed through the free Apple ID/3uTools
path does **not** obtain an APNs-capable provisioning profile. Background push
on iPhone therefore requires a normal signed build with an App ID and
provisioning profile that allow Push Notifications, the APNs key uploaded to
Firebase, `STARFORGE_PUSH_ENTITLEMENTS=Runner/PushNotifications.entitlements`,
and the matching `APS_ENVIRONMENT` (`development` or `production`). Firebase's
[Flutter setup guide](https://firebase.google.com/docs/flutter/setup) and
[FCM Apple setup guide](https://firebase.google.com/docs/cloud-messaging/flutter/get-started)
cover the owner-side Firebase/APNs steps. Codemagic also documents how YAML
workflows [import environment-variable groups](https://docs.codemagic.io/yaml-basic-configuration/configuring-environment-variables/).

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
