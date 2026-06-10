# Submitting Pastry to the Mac App Store

A start-to-finish guide. Budget a weekend for the first submission; updates
after that take minutes.

## 0. Read this first: the auto-paste caveat

The Mac App Store requires **App Sandbox**. Pastry's clipboard *watching* is
fine sandboxed (no entitlement needed), and so is the global hotkey. The one
sensitive piece is **auto-paste**: Pastry synthesizes ⌘V with `CGEventPost`,
which only works after the user grants **Accessibility** permission.

This is allowed — established App Store clipboard managers (Paste, PasteNow)
do exactly this — but it's the part reviewers look at. Two rules keep you safe:

1. **Degrade gracefully.** If permission isn't granted, the app must still
   work (Pastry already does: it copies the item and the user pastes manually).
2. **Explain it.** In the App Review notes, say exactly why you need
   Accessibility and what happens without it.

If review ever pushes back, ship v1 with auto-paste off by default ("Press ⌘V
after picking an item") and enable it as an opt-in setting.

## 1. Enroll in the Apple Developer Program

- https://developer.apple.com/programs/ — $99/year, personal or company.
- Use the Apple ID you want to publish under. Approval is usually < 48h.

## 2. Reserve the app in App Store Connect

- https://appstoreconnect.apple.com → My Apps → **+ → New App**.
- Platform: macOS. Name: **Pastry** — names are first-come-first-served; if
  taken, try "Pastry — Clipboard History", "Pastry Clipboard", or fall back to
  another name entirely.
- Bundle ID: register `com.asray.pastry` first at
  https://developer.apple.com/account/resources/identifiers (type: App IDs → App).
- SKU: anything unique, e.g. `pastry-001`. Primary language, then Create.

## 3. Wrap the code in an Xcode project

The SwiftPM build in this repo is great for development, but archiving and
uploading is far easier from Xcode:

1. Xcode → File → New → Project → **macOS → App**. Product name `Pastry`,
   bundle id `com.asray.pastry`, interface SwiftUI, language Swift.
2. Delete the template `PastryApp.swift` and `ContentView.swift`.
3. Drag everything in `Sources/Pastry/` into the project (copy items).
   `main.swift` is the entry point — no `@main` struct needed.
4. Target → Info tab, add:
   - `Application is agent (UIElement)` = YES (this is `LSUIElement` — no Dock icon)
   - `ITSAppUsesNonExemptEncryption` = NO (skips export-compliance questions)
5. Target → Signing & Capabilities:
   - Team: your developer team, "Automatically manage signing" on.
   - **App Sandbox** capability must be present (it is by default). Pastry
     needs **no** extra sandbox entitlements — no network, no file access.
6. Replace `AppIcon` in Assets.xcassets — drag `Resources/AppIcon-1024.png`
   into the 1024pt slot (Xcode 14+ can use a single 1024 image: set the asset
   to "Single Size").
7. General tab: set Version `1.0`, Build `1`, Category **Productivity**,
   minimum deployment macOS 13.0.
8. Build and run once. Re-grant Accessibility to this new build
   (System Settings → Privacy & Security → Accessibility) and verify:
   copy a few things, ⌘⇧V, paste, pin, clear all.

## 4. Prepare the listing assets

- **Icon**: comes from the app bundle automatically (`AppIcon-1024.png` is the master).
- **Screenshots**: at least one, in an accepted size — 1280×800, 1440×900,
  2560×1600, or 2880×1800. Open the panel over a nice desktop, `⌘⇧5` to
  capture, then resize/pad to an exact accepted size. 3–5 screenshots showing
  the panel, pinning, and image history is ideal.
- **Description** (draft):

  > Pastry brings Windows-style clipboard history to your Mac. Press ⌘⇧V
  > anywhere to see everything you've copied — text and images — and paste
  > any of it back with a click or a keystroke. Pin the things you reuse
  > daily; they survive Clear All and never expire. Pastry lives in your
  > menu bar, stays out of your way, and never sends your clipboard anywhere:
  > everything is stored locally on your Mac.

- **Keywords**: `clipboard,history,paste,copy,clipboard manager,snippets,productivity`
- **Support URL**: any page you control (a GitHub repo README works).
- **Privacy policy URL**: required. One paragraph on a page you control:
  "Pastry stores clipboard history locally on your device. No data is
  collected, transmitted, or shared." (GitHub Pages or a gist link is fine.)

## 5. Fill in App Privacy

App Store Connect → App Privacy → **Data Not Collected**. This is accurate:
everything stays in `~/Library/Application Support/Pastry/` (in the sandbox,
under the app container). Users notice and love this label on a clipboard app.

## 6. Pricing & availability

Pricing section → pick Free (or a price tier). Clipboard managers do sell —
Paste is subscription, PasteNow is ~$10 one-time — but free is the easy
first release.

## 7. Archive and upload

1. In Xcode: select **Any Mac** as the destination → Product → **Archive**.
2. Organizer opens → Distribute App → **App Store Connect** → Upload.
   Xcode handles signing, provisioning, and the upload in one flow.
3. Wait ~15 minutes for processing, then the build appears under your app's
   version in App Store Connect. (TestFlight is available here too if you
   want beta testers first.)

## 8. Submit for review

1. Select the processed build on the version page.
2. **App Review notes** — paste something like:

   > Pastry is a clipboard history manager (a Windows Win+V equivalent).
   > It requests Accessibility permission solely to synthesize a single ⌘V
   > keystroke that pastes the user's chosen history item into the app they
   > were using. If permission is declined, the app remains fully functional:
   > selecting an item copies it to the clipboard and the user pastes
   > manually. No clipboard data ever leaves the device.
   >
   > To test: launch Pastry (menu bar icon appears), copy a few pieces of
   > text, press ⌘⇧V, choose an item.

3. Submit. First reviews typically take 1–3 days.

## 9. Common rejection reasons (and the fix)

| Risk | Mitigation |
|---|---|
| Guideline 2.4.5 — sandbox violations | Keep App Sandbox on; we use no restricted APIs beyond CGEventPost-with-consent |
| Guideline 5.1.1 — permission purpose unclear | The review notes above; consider an in-app explainer window before the Accessibility prompt |
| Crashes on reviewer's machine | Test a clean build on a second user account before submitting |
| Metadata mismatch | Screenshots must show the actual current UI |

## Alternative: skip the App Store

For a menu-bar utility like this, direct distribution is genuinely easier and
removes all sandbox/review constraints:

1. Get a **Developer ID Application** certificate (same $99 program).
2. `codesign --deep --options runtime -s "Developer ID Application: Your Name" Pastry.app`
3. Notarize: zip the app, `xcrun notarytool submit Pastry.zip --keychain-profile <profile> --wait`,
   then `xcrun stapler staple Pastry.app`.
4. Distribute the zip/dmg from a website or GitHub Releases.

Many successful clipboard managers (Maccy, for years) shipped exactly this way.
