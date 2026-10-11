# Guide for AI agents: install murmur

Follow these steps in order. Stop at a step that says ASK THE HUMAN.

## 1. Check the machine

Run: `uname -m` and `sw_vers -productVersion`.

- `uname -m` must print `arm64`. If not, stop. The app does not support Intel Macs.
- The macOS version must be 14 or newer.

## 2. Choose a path

Path A installs the finished app. Path B builds from source. Use Path A unless the human asks for source.

### Path A: install the app

1. Download the newest `murmur-*-arm64.zip` from the Releases page of this repository.
2. Run `unzip -q murmur-*-arm64.zip`. Do not use `ditto -x` in a restricted shell. It can break the framework links.
3. Run `mv murmur.app /Applications/`.
4. Run `xattr -dr com.apple.quarantine /Applications/murmur.app`.
5. Run `open /Applications/murmur.app`.

### Path B: build from source

1. Run `xcode-select -p`. If it fails, run `xcode-select --install`. ASK THE HUMAN to finish the dialog.
2. Run `scripts/fetch-deps.sh`. It downloads about 290 MB and checks a checksum.
3. Run `./build.sh`. The script signs with a `murmur-dev` certificate if one exists. Otherwise it signs ad hoc.
4. Run `open murmur.app`.

An ad hoc signature changes on each build. macOS then forgets the Accessibility permission. Tell the human to grant it again after each rebuild.

## 3. Grant permissions

ASK THE HUMAN. An agent cannot click these dialogs.

1. Microphone: allow when the first recording starts.
2. Accessibility: System Settings, Privacy & Security, Accessibility. Turn on murmur.

The menu-bar icon shows a checklist of both permissions and the model state.

## 4. Test the install

1. Run `pgrep -l murmur`. It must print a process.
2. Make a test clip: `say -o /tmp/t.aiff "the quick brown fox" && ffmpeg -y -i /tmp/t.aiff -ar 16000 -ac 1 -c:a pcm_s16le /tmp/t.wav`.
3. Run `/Applications/murmur.app/Contents/MacOS/murmur --transcribe /tmp/t.wav`.
4. The output must contain the sentence and a time in ms. A 3 s clip takes about 200 to 250 ms on an M1.
5. ASK THE HUMAN to click in a text field, press Ctrl+Option+Space, speak, and press it again.

## Problems

- The hotkey does nothing: another app uses Ctrl+Option+Space. Quit that app.
- The text does not paste: turn on Accessibility for murmur. Click in an editable field first.
- To see logs, run: `open --stdout /tmp/murmur.log --stderr /tmp/murmur.log /Applications/murmur.app`.
- The Swift build fails with `PreviewsMacros`: keep KeyboardShortcuts at 1.15.0. Newer versions need full Xcode.
