# App Review reply — Submission c7777ab6-696a-4ef1-af05-cf61466ab7c3

Paste the block below into the App Store Connect message thread (Resolution
Center) for version 1.0 (1). It addresses both guidelines in one reply:
5.2.5 is resolved by editing metadata; 2.4.5 is an appeal.

> **Before sending:** in App Store Connect → App Information, change the
> Subtitle from "Clipboard history for your Mac" to **"Clipboard history
> manager"**, then send this reply. The reply references that change.

---

Hello, and thank you for the detailed review.

**Guideline 5.2.5 — Intellectual Property (subtitle)**

We have removed the term "Mac" from the app subtitle. The subtitle has been
updated to "Clipboard history manager," which contains no Apple product or
service names. Please let us know if any other metadata needs adjustment.

**Guideline 2.4.5 — Accessibility usage**

We would respectfully like to explain why Pastry's use of the Accessibility
permission is, in fact, an accessibility feature, and ask you to reconsider.

Pastry is a clipboard-history utility (a macOS equivalent of Windows' Win+V).
Its single use of Accessibility is to deliver the item the user has selected
into the app they were just working in — by posting one ⌘V keystroke to the
frontmost application after the user explicitly chooses an item. This is the
*only* purpose for which the permission is requested.

We believe this serves accessibility directly:

1. **It reduces the physical actions required to complete a task.** Without
   auto-paste, retrieving a past clipboard item requires the user to open the
   panel, select an item, dismiss the panel, manually return focus to their
   document, and then perform the ⌘V chord themselves. Auto-paste collapses
   that into a single selection. For users with motor impairments, repetitive
   strain injury, tremor, or limited dexterity, eliminating that extra
   modifier-key chord on every paste is a meaningful accessibility benefit —
   the same category of benefit as keyboard shortcuts, dwell control, or
   sticky keys.

2. **The Accessibility API is the only API macOS provides for this.** There is
   no sandbox-compatible alternative for delivering synthesized input into the
   frontmost application. We are not using the API to inspect, monitor, read,
   or automate other apps — we post exactly one ⌘V event, only in direct
   response to an explicit user action, and only to the app the user themselves
   had in front.

3. **The permission is strictly optional and the app is fully functional
   without it.** If the user declines Accessibility access, Pastry simply
   writes the selected item to the clipboard and the user presses ⌘V manually.
   No feature is gated behind the permission except the convenience of
   auto-paste itself.

4. **No data leaves the device.** Pastry has no network code, no accounts, and
   no analytics. The Accessibility permission is never used to read other apps'
   contents — only to send a single paste keystroke.

If, after this explanation, you would still prefer that this functionality be
provided through a dedicated, non-Accessibility API, we will gladly file an
enhancement request via Feedback Assistant as suggested. We would appreciate
guidance on whether such an API exists for delivering a paste into the
frontmost app from a sandboxed Mac App Store application; to our knowledge the
Accessibility API is currently the only supported mechanism.

Thank you for your time and consideration.

Asray Gopa
asraygopa@gmail.com
