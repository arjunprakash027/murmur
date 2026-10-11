# P2: global hotkey + paste at cursor (macOS Swift menu-bar app)
Researched 2026-10-11. Read-only. Sources are mostly forums/READMEs/community guides; no Apple doc states the permission matrix outright. Verify on target macOS before committing.

## (a) Global toggle hotkey

| Option | Permission | Consumes key? | Fn? | Notes |
|---|---|---|---|---|
| Carbon `RegisterEventHotKey` (direct, or via KeyboardShortcuts) | None reported | Yes | No (needs a real key + modifiers) | Legacy API but still present on macOS 26 |
| `CGEventTap` | Input Monitoring (listen-only); Accessibility to consume/modify | Yes (active tap) | Yes, via `flagsChanged` + `maskSecondaryFn` | Reliability issues, see gotchas |
| `NSEvent.addGlobalMonitorForEvents` | Accessibility (per community guide) | No (frontmost app still sees key) | Observe only | Cannot swallow the keystroke |

Evidence:
- KeyboardShortcuts README: sandbox + Mac App Store compatible; FAQ says no permission dialogs; built on Carbon APIs. https://swiftpackageregistry.com/sindresorhus/KeyboardShortcuts , https://cocoapods.org/pods/KeyboardShortcuts (mirrors; canonical README not fetched)
- go-macos/hotkey README: RegisterEventHotKey needs no TCC grant on macOS 26.x; event tap and NSEvent monitor need Accessibility. One developer's observation. https://pkg.go.dev/github.com/go-macos/hotkey
- Apple forum reply: Carbon is legacy, prefers CGEventTap; tap pairs with `CGPreflightListenEventAccess` / `CGRequestListenEventAccess`. https://developer.apple.com/forums/thread/735223
- App may fail to show in Input Monitoring list even after request calls (macOS 15). https://developer.apple.com/forums/thread/828052
- Revoking Accessibility while a tap is active can freeze system input. https://developer.apple.com/forums/thread/844416
- Fn flag: Apple defines `maskSecondaryFn`, mostly laptop keyboards. https://developer.apple.com/documentation/coregraphics/cgeventflags.md

## Is Fn usable?
Only as a listen-only tap on `flagsChanged` (hold/tap detection). Not registrable via Carbon. Fn/Globe also collides with the system emoji/dictation action (user must set "Press Globe key" to Do Nothing; not verified here). Posting synthetic Fn events is reported broken on Sequoia (flag vs HID usage ID mismatch): https://developer.apple.com/forums/thread/766200 . Irrelevant for reading, relevant only for testing.

## Recommendation (a)
Use `KeyboardShortcuts` (Carbon underneath) for a toggle chord, e.g. Ctrl+Opt+Space. Zero permissions, user-rebindable, no tap fragility. Add a CGEventTap Fn option later only if wanted, as an opt-in extra.
Gotchas: the chord is swallowed, good for toggle; keys with no modifier are not allowed for some combos (e.g. plain letters), so require a modifier. No media keys. Carbon is legacy, but README expects replacement APIs before removal.

## (b) Paste at cursor

Flow (what Maccy does): write text to `NSPasteboard.general`, then post Cmd+V with `CGEvent` (keycode 9, `.maskCommand`). https://app.unpkg.com/major-ai-skills@2.3.0/files/skills/maccy/SKILL.md (third-party summary)
- Permission: posting CGEvents needs Accessibility (kTCCServicePostEvent). Sandboxed App Store clipboard managers doing this were rejected under Guideline 2.4.5; compliance unresolved. https://developer.apple.com/forums/thread/820594
- Restore old clipboard: snapshot all items/types first, restore asynchronously after ~200 ms (Chromium waits that long; some apps read the clipboard several times per paste). https://chromium.googlesource.com/chromium/src.git/+/lkgr/ash/quick_insert/quick_insert_clipboard_insertion.cc
- Concealed type: also set `org.nspasteboard.ConcealedType` (and `TransientType`) so clipboard managers like Maccy skip the dictated text. Convention, not Apple API. Same Maccy link.
- Detect other writers: compare `changeCount` before restoring; if it changed, someone else copied, so skip restore.
- AXValue fallback: set `kAXSelectedTextAttribute` on the focused element (`AXUIElementCopyAttributeValue` on system-wide `kAXFocusedUIElementAttribute`). Also needs Accessibility. Fails in Electron/web views, terminals and many custom editors. Prefer selected-text over `AXValue` (AXValue replaces the whole field). Not source-verified here; from general API knowledge.
- CGEvent flakiness: forum report of identical CGEvent paste code that stopped working. https://developer.apple.com/forums/thread/773989

## Recommendation (b)
Clipboard + synthesized Cmd+V, with ConcealedType, changeCount-guarded restore after ~200 ms. Use AXSelectedText insertion only as a fallback when the paste target rejects it. Requires one Accessibility grant, which also covers the fallback. Ship non-sandboxed (Developer ID, notarized); App Store likely rejects this.

## Net permission ask
Accessibility only (for paste). Hotkey needs none. Add Input Monitoring only if Fn is added later.
Gotchas: Accessibility grant is tied to code signature; re-signing with a new identity resets it, so sign with a stable Developer ID even in dev. Check `AXIsProcessTrustedWithOptions` at launch and prompt. Microphone permission is separate.

## Open items to test
- Carbon hotkey really needs no prompt on current macOS (only secondary sources).
- Paste works in terminals, Electron, password fields (secure input blocks synthetic keys).
