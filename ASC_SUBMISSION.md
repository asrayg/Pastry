# App Store Connect — Pastry submission checklist

Every field you'll see in App Store Connect (ASC), in order, with the exact
value to paste. Anything marked **[your call]** is a decision; everything else
is fill-in-the-blank. Values come straight from the app's `Info.plist` and
`Pastry.entitlements`, so they match what you'll actually upload.

App reference values (don't retype, just confirm these match):

| Thing | Value |
|---|---|
| Platform | macOS |
| Bundle ID | `com.asray.pastry` |
| Version (CFBundleShortVersionString) | `1.0` |
| Build (CFBundleVersion) | `1` |
| Category | Productivity |
| Minimum macOS | 13.0 |
| Encryption | None (`ITSAppUsesNonExemptEncryption = NO`) |
| Copyright | © 2026 Asray Gopa |

---

## 0. Before ASC — make sure the build is uploadable

You can't fill out a build/version in ASC until a processed build exists.

1. Sign in to Xcode once: **Xcode → Settings → Accounts → +** → your developer Apple ID.
2. `./archive.sh` → produces `build/appstore/Pastry.pkg`.
3. Upload it with **Transporter** (free on the Mac App Store — drag the `.pkg` in)
   or via Xcode Organizer → Distribute App → App Store Connect.
4. Wait ~5–15 min for it to show as "processed" under the version's Build section.

---

## 1. Create the app record

**My Apps → + → New App**

| Field | What to enter |
|---|---|
| Platforms | ☑ macOS |
| Name | `Pastry`  (if taken: `Pastry — Clipboard History`) |
| Primary language | English (U.S.) |
| Bundle ID | `com.asray.pastry` (pick from dropdown) |
| SKU | `pastry-001`  (internal only, any unique string) |
| User Access | Full Access |

If the bundle ID isn't in the dropdown, the archive/upload step hasn't
registered the App ID yet — do section 0 first.

---

## 2. App Information (left sidebar → General → App Information)

| Field | What to enter |
|---|---|
| Name | `Pastry` |
| Subtitle | `Clipboard history manager`  (max 30 chars) |
| Privacy Policy URL | **required** — see section 6 |
| Category — Primary | Productivity |
| Category — Secondary | Utilities  **[your call, optional]** |
| Content Rights | "No, it does not contain, show, or access third-party content" |
| Age Rating | Click Edit → answer **No** to everything → results in **4+** |

---

## 3. Pricing and Availability (sidebar → Pricing and Availability)

| Field | What to enter |
|---|---|
| Price | **Free** (Tier 0)  **[your call — easiest first release]** |
| Availability | All countries and regions |
| Distribution | Make available on the Mac App Store |

---

## 4. The version page (sidebar → macOS App → 1.0 Prepare for Submission)

This is the big one. Fields top to bottom:

### Version Information
| Field | Value |
|---|---|
| Version | `1.0` |

### Screenshots  (required — at least 1)
- Accepted sizes: **1280×800, 1440×900, 2560×1600, or 2880×1800**.
- Capture: open the panel with **⌘⇧V** over a clean desktop, screenshot with ⌘⇧5.
- Resize to an exact accepted size:
  `sips -z 1800 2880 shot.png --out shot-store.png`
- Add 1–5. They must show the **real current UI** (mismatch = rejection).

### Promotional Text  (optional, 170 chars, editable without review)
```
Press ⌘⇧V to bring back anything you've copied — text, images, screenshots. Everything stays local on your Mac.
```

### Description  (paste as-is)
```
Pastry brings Windows-style clipboard history to your Mac. Press ⌘⇧V anywhere to see everything you've copied — text, images, and screenshots — and paste any of it back with a click or a keystroke. Take a screenshot and it's instantly ready to paste. Pin the things you reuse daily; they survive Clear All and never expire. Pastry lives in your menu bar, stays out of your way, and never sends your clipboard anywhere: everything is stored locally on your Mac.

FEATURES
• Instant history — every copy (⌘C) is recorded automatically: text, images, and screenshots.
• Quick recall — press ⌘⇧V to open the history panel right at your cursor.
• Keyboard-first — ↑/↓ to select, ↩ to paste into the app you were in, or just click.
• Pin what matters — pinned items survive Clear All and never age out.
• Screenshot ready — take a screenshot and it's on the clipboard, ready to paste.
• Private by design — nothing ever leaves your Mac. No accounts, no cloud, no tracking.
• Out of the way — lives in your menu bar, no Dock clutter.
```

### Keywords  (max 100 chars, comma-separated, no spaces after commas)
```
clipboard,history,paste,copy,clipboard manager,screenshot,snippets,productivity
```

### Support URL  (required)
```
https://github.com/asrayg/Pastry
```

### Marketing URL  (optional)
```
https://github.com/asrayg/Pastry
```

### Build
- Click **+ / Select a build**, choose the processed build (1.0 / build 1).
- If nothing appears, the upload (section 0) isn't processed yet.

### General App Information (lower on the same page)
| Field | Value |
|---|---|
| Copyright | `© 2026 Asray Gopa` |
| Version | `1.0` |
| Routing App Coverage File | leave blank (not a maps app) |

### App Review Information
| Field | Value |
|---|---|
| Sign-in required | **No** (toggle off — no account in the app) |
| Contact First/Last name | Asray / Gopa |
| Phone | your number |
| Email | asraygopa@gmail.com |
| Notes | paste the block below |

App Review notes:
```
Pastry is a clipboard history manager (a Windows Win+V equivalent). It requests Accessibility permission solely to synthesize a single ⌘V keystroke that pastes the user's chosen history item into the app they were using. If permission is declined, the app remains fully functional: selecting an item copies it to the clipboard and the user pastes manually. No clipboard data ever leaves the device.

To test: launch Pastry (a menu bar icon appears), copy a few pieces of text, press ⌘⇧V, then choose an item.
```

### Version Release
- **[your call]** — "Automatically release this version" is the simple choice
  for a first app. (Manual release lets you pick the moment after approval.)

---

## 5. App Privacy (sidebar → App Privacy)  — required before submitting

Click **Get Started / Edit**:

| Question | Answer |
|---|---|
| Do you or your partners collect data from this app? | **No** → "Data Not Collected" |

That's the whole section — Pastry stores everything locally and has no network
code, so nothing is collected. (Confirm there's genuinely no analytics/network
SDK; there isn't in this codebase.)

---

## 6. Privacy Policy — the one thing you must host somewhere

ASC requires a **Privacy Policy URL** (section 2). It can be any page you
control. Easiest: add this to the GitHub repo's README or a `PRIVACY.md`, then
use its URL.

Text to publish:
```
Privacy Policy — Pastry

Pastry stores your clipboard history locally on your device, in
~/Library/Application Support/Pastry. No data is collected, transmitted,
or shared. Pastry has no servers, no analytics, and makes no network
connections. You can clear your history at any time from the menu bar.

Contact: asraygopa@gmail.com
```
Then set Privacy Policy URL to e.g. `https://github.com/asrayg/Pastry/blob/main/PRIVACY.md`.

---

## 7. Submit

1. Top right of the version page → **Add for Review** → **Submit to App Review**.
2. Export compliance: because `ITSAppUsesNonExemptEncryption = NO` is already in
   `Info.plist`, ASC should skip the encryption questions. If it still asks:
   answer **No** to "uses non-exempt encryption."
3. First reviews typically take 1–3 days.

---

## Quick "is everything filled?" checklist

- [ ] App record created (name, bundle ID, SKU)
- [ ] Subtitle + Category + Age Rating (App Information)
- [ ] Pricing set (Free)
- [ ] 1–5 screenshots at an accepted size, showing real UI
- [ ] Description + Keywords + Support URL
- [ ] Build selected (processed, 1.0/1)
- [ ] Copyright
- [ ] App Review notes + contact + sign-in = No
- [ ] App Privacy = Data Not Collected
- [ ] Privacy Policy URL hosted and entered
- [ ] Submitted for review
```
