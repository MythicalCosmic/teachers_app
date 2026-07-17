# Signed iPhone IPA

The repository includes a manual GitHub Actions workflow named **Build signed
iOS IPA**. It performs a release archive on a macOS runner, validates the IPA
container, checks the app signature, and uploads the `.ipa` as a workflow
artifact.

## Apple material required

Create a Development or Ad Hoc provisioning profile for
`uz.starforge.starforgeEdu`. The target iPhone must be registered in that
profile. Export the matching Apple signing identity from Keychain Access as a
password-protected `.p12` file.

Add these encrypted GitHub Actions repository secrets:

| Secret | Value |
|---|---|
| `IOS_CERTIFICATE_BASE64` | Base64-encoded `.p12` file |
| `IOS_CERTIFICATE_PASSWORD` | Password used when exporting the `.p12` |
| `IOS_PROVISIONING_PROFILE_BASE64` | Base64-encoded `.mobileprovision` file |
| `IOS_KEYCHAIN_PASSWORD` | A temporary password used only by the runner |

On PowerShell, encode either file without line breaks:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes('certificate.p12'))
[Convert]::ToBase64String([IO.File]::ReadAllBytes('profile.mobileprovision'))
```

## Build and install

1. Open the repository's **Actions** tab.
2. Choose **Build signed iOS IPA** and **Run workflow**.
3. Keep `development` for a directly registered test iPhone, or choose
   `ad-hoc` for an Ad Hoc profile.
4. Download the `starforge-staff-...-ipa` artifact after the job succeeds.
5. Install the contained IPA with Apple Configurator, Xcode Devices and
   Simulators, or another trusted installer supported by the signing method.

The workflow deliberately fails early when the certificate is unusable, the
profile does not match the bundle ID, or the final archive lacks the required
`Payload/<App>.app/` structure.
