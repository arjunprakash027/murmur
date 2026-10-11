# How we built murmur

This page records the whole process. It took one session.

## 1. Goal

We wanted one flow: press a hotkey, speak, press it again, and paste the text at the cursor. The speech model must run on the Mac.

## 2. Study of an existing app

We looked at a commercial dictation app to learn how this flow works. We read its installed files only. We did not copy any of its code. We did not run its code under a debugger.

What we found:

- The app is an Electron app. A small native Swift helper listens for keys and pastes text.
- The two parts talk through JSON on standard input and output.
- The app encodes audio to Opus and sends it to a cloud server.
- The helper pastes with the clipboard. It restores your old clipboard afterwards.

The cloud server is the main difference. murmur runs the model on the Mac.

## 3. Decisions

| Question | Choice | Reason |
|---|---|---|
| Speech model | whisper.cpp, `base.en` | Small (142 MB). Runs well on an M1 Air. Uses the GPU through Metal. |
| App shape | One Swift menu-bar app | No Electron. Fewer parts. |
| Hotkey | KeyboardShortcuts library, Ctrl+Option+Space | Needs no permission. |
| Paste | Clipboard, then Cmd+V, then restore the clipboard | Works in most apps. Needs Accessibility only. |

Sources for the hotkey and paste choice are in [research-hotkey-paste.md](research-hotkey-paste.md).

## 4. Plan

1. Scaffold the Swift package and the app bundle.
2. Add the global hotkey.
3. Record the microphone as 16 kHz mono floats.
4. Load whisper.cpp and transcribe.
5. Paste at the cursor.
6. Connect all parts.

We drew the plan on a tldraw board and tracked it as pieces in a task tool.

## 5. Build

One agent built step 1. Then four agents built steps 2 to 5 at the same time. Each agent worked in its own git worktree and edited one file. Three different AI models did the work: Claude, Grok and Codex. We merged the branches when each build passed. A person then tested the live flow.

## 6. Problems we found

- **KeyboardShortcuts 1.16 and newer fail to build** without full Xcode. They use `#Preview`. We pinned version 1.15.0.
- **Paste did nothing at first.** Some apps report success when we set text through the Accessibility API, but they insert nothing. We now send Cmd+V first. We use the Accessibility API only if Cmd+V fails.
- **Output was silent.** The system held standard output in a buffer. We turned buffering off and added log lines.
- **Unzipping broke the app.** `ditto` stored extra `._` files. They broke the code signature. We now zip with `--norsrc --noextattr`.

## 7. Result

On an M1 MacBook Air, a 3 s clip transcribes in about 224 ms. The full loop works in a text field.

## 8. Packaging

The build script copies the model into the app bundle and embeds the whisper framework. The app links only to system libraries. `./build.sh --dist` writes a zip of about 129 MB.

We sign the app with a local certificate. It is not notarized. Notarization needs a paid Apple Developer account.

## 9. Not done

- Esc to cancel a recording.
- Launch at login.
- Tests in terminals and in Electron apps.
- Notarization.
