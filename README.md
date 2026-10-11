# murmur

Local push-to-talk dictation for macOS. Press a hotkey, speak, press it again, and the text from a local speech model is pasted at your cursor. Nothing leaves your Mac.

## Install (Apple Silicon, macOS 14+)

1. Download `murmur-0.1-arm64.zip` from Releases and unzip it.
2. Move `murmur.app` to Applications.
3. The app is not notarized yet. On first launch, right-click it, choose Open, then Open again. If macOS still blocks it, run `xattr -dr com.apple.quarantine /Applications/murmur.app`.
4. Allow Microphone and Accessibility when asked. Accessibility is needed to paste.

## Use

Click into a text field, press **Ctrl+Option+Space**, speak, press it again. A small pill shows Listening (live voice bars), Transcribing and Pasted.

## Build from source

```
scripts/fetch-deps.sh     # whisper.cpp framework and base.en model
./build.sh                # builds murmur.app (signed with a local "murmur-dev" certificate)
./build.sh --dist         # also writes dist/murmur-<version>-arm64.zip
```

Uses whisper.cpp (base.en, Metal) and KeyboardShortcuts. Needs only the Xcode Command Line Tools.
