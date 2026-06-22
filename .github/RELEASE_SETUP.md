# CI release to the App Store — setup

`.github/workflows/release.yml` builds, archives, and uploads Pastry to App Store
Connect — fully unattended. It uses **cloud-managed automatic signing**: no
certificates are stored in the repo. `-allowProvisioningUpdates` plus an App
Store Connect API key let Xcode create and manage the distribution certificate
and provisioning profile during the run. This mirrors the proven `pippa-mono`
iOS release pipeline (same team, `L6LUXM357X`).

## Secrets (3)

The same App Store Connect API key works across the team's apps:

| Secret | Value |
|---|---|
| `ASC_API_KEY_P8` | the full contents of the `AuthKey_XXXXXX.p8` file |
| `ASC_KEY_ID` | the key's Key ID (the `XXXXXX` in the filename) |
| `ASC_ISSUER_ID` | the key's Issuer ID (App Store Connect → Users and Access → Integrations) |

Set them with the `gh` CLI from this repo:

```sh
gh secret set ASC_API_KEY_P8 < AuthKey_XXXXXX.p8
gh secret set ASC_KEY_ID --body "XXXXXX"
gh secret set ASC_ISSUER_ID --body "<issuer-id>"
```

## Before the first upload

The bundle ID `com.asray.pastry` must already exist as an app record in App Store
Connect (My Apps → **+ New App**). `xcodebuild` uploads a build to an existing
app; it doesn't create the app. See `APP_STORE.md` for listing details.

## Releasing

```sh
# bump CFBundleVersion in Info.plist (must increase for every upload), then:
git tag v1.0.1
git push origin v1.0.1
```

Or use the **Run workflow** button in the Actions tab. On success the build shows
up in App Store Connect → TestFlight / the version's Build section within a few
minutes, ready to attach to a submission.

## Notes

- **Every upload needs a higher `CFBundleVersion`** (the `1` in `Info.plist`).
  App Store Connect rejects a reused build number.
- The workflow runs on `macos-15`. Bump it if a newer Xcode/SDK is required.
