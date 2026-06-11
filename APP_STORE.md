# Pastry — Mac App Store submission

Almost everything is already set up in this repo. Here's what exists, the one
thing you must do once, and the release routine.

## Already done ✅

- **Xcode project** — `Pastry.xcodeproj`, wired to the sources, `Info.plist`,
  the app icon, and a shared scheme. Builds and signs with your team
  (`L6LUXM357X`) using automatic signing.
- **App Sandbox** — `Pastry.entitlements` (required for the App Store);
  verified the built app is sandboxed + hardened runtime.
- **Bundle config** — `com.asray.pastry`, category Productivity, version 1.0,
  `ITSAppUsesNonExemptEncryption = NO` (skips export-compliance questions),
  agent app (no Dock icon).
- **Icon** — generated `.icns` in the bundle; `Resources/AppIcon-1024.png` is
  the 1024px master for App Store Connect.
- **Archive script** — `./archive.sh` archives and exports a store-ready
  `build/appstore/Pastry.pkg`.

## One-time setup (you, ~1 minute)

Xcode has no Apple ID session on this Mac, which is the only reason
`./archive.sh` can't finish — it needs to create your **Mac Installer
Distribution** certificate (it said: "can be created silently" but
"did not find session").

1. Open Xcode → **Settings → Accounts → +** → sign in with your developer Apple ID.
2. Run `./archive.sh` again. With a session available it will create the
   installer certificate, register the `com.asray.pastry` App ID, and generate
   the provisioning profile automatically (`-allowProvisioningUpdates`).

If the command line still balks, the GUI always works: open `Pastry.xcodeproj`,
Product → **Archive**, then in Organizer: **Distribute App → App Store Connect**.

## Create the app record (App Store Connect, ~5 minutes)

1. https://appstoreconnect.apple.com → My Apps → **+ New App**.
2. Platform macOS, name **Pastry** (if taken: "Pastry — Clipboard History"),
   bundle ID `com.asray.pastry`, SKU `pastry-001`.

## Listing assets

- **Screenshots**: 1–5 images at 1280×800, 1440×900, 2560×1600, or 2880×1800.
  Open the panel (⌘⇧V) over a clean desktop, capture with ⌘⇧5, then resize:
  `sips -z 1800 2880 shot.png --out shot-store.png`
- **Description** (ready to paste):

  > Pastry brings Windows-style clipboard history to your Mac. Press ⌘⇧V
  > anywhere to see everything you've copied — text, images, and screenshots —
  > and paste any of it back with a click or a keystroke. Take a screenshot
  > and it's instantly ready to paste. Pin the things you reuse daily; they
  > survive Clear All and never expire. Pastry lives in your menu bar, stays
  > out of your way, and never sends your clipboard anywhere: everything is
  > stored locally on your Mac.

- **Keywords**: `clipboard,history,paste,copy,clipboard manager,screenshot,snippets,productivity`
- **Support URL**: any page you control (GitHub repo works).
- **Privacy policy URL** (required): one paragraph on any page you control —
  "Pastry stores clipboard history locally on your device. No data is
  collected, transmitted, or shared."
- **App Privacy** section: select **Data Not Collected**.
- **Pricing**: Free is the easy first release (PasteNow charges ~$10 one-time,
  Paste is subscription — there is a market if you want to charge later).

## Upload & submit

1. `./archive.sh` → produces `build/appstore/Pastry.pkg`.
2. Upload with the **Transporter** app (free on the Mac App Store) — drag the
   .pkg in — or use Xcode Organizer's Distribute flow instead.
3. In App Store Connect, select the processed build, then paste this into
   **App Review notes**:

   > Pastry is a clipboard history manager (a Windows Win+V equivalent).
   > It requests Accessibility permission solely to synthesize a single ⌘V
   > keystroke that pastes the user's chosen history item into the app they
   > were using. If permission is declined, the app remains fully functional:
   > selecting an item copies it to the clipboard and the user pastes
   > manually. No clipboard data ever leaves the device.
   >
   > To test: launch Pastry (menu bar icon appears), copy a few pieces of
   > text, press ⌘⇧V, choose an item.

4. Submit. First reviews typically take 1–3 days.

## Known sandbox caveats (be upfront in review notes if asked)

- **Auto-paste** needs user-granted Accessibility. Established store apps
  (Paste, PasteNow) ship this; the key is degrading gracefully, which Pastry
  does (copy-only without the permission).
- **Screenshot pickup** reads new files from the screenshot folder (usually
  Desktop). In the sandboxed build this triggers the standard macOS
  files-access consent; if the user declines, screenshots taken with
  ⌃⌘⇧4 (copy-to-clipboard) are still captured via the clipboard. If review
  pushes back, ship v1 with the file watcher behind an opt-in setting.

## Common rejection reasons (and the fix)

| Risk | Mitigation |
|---|---|
| 2.4.5 — sandbox violations | Sandbox is on; no restricted APIs beyond consent-gated CGEventPost |
| 5.1.1 — unclear permission purpose | The review notes above; optionally add an in-app explainer before the prompt |
| Crashes on reviewer's machine | Test a clean build on a second user account first |
| Metadata mismatch | Screenshots must show the actual current UI |

## Alternative: skip the App Store entirely

Direct distribution avoids the sandbox and review:

```sh
codesign --deep --options runtime -s "Developer ID Application: Asray Gopa" build/Pastry.app
ditto -c -k --keepParent build/Pastry.app Pastry.zip
xcrun notarytool submit Pastry.zip --keychain-profile <profile> --wait
xcrun stapler staple build/Pastry.app
```

(Requires a Developer ID Application certificate — create it in Xcode's
Accounts settings → Manage Certificates.) Maccy shipped this way for years.
