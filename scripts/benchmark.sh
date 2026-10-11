#!/bin/bash
# Measures murmur speed and memory on this Mac. Needs murmur.app, `say` and ffmpeg.
set -euo pipefail
APP="${1:-murmur.app}"
BIN="$APP/Contents/MacOS/murmur"
D=$(mktemp -d)
say_clip() { say -v Samantha -o "$D/$1.aiff" "$2"; ffmpeg -loglevel error -y -i "$D/$1.aiff" -ar 16000 -ac 1 -c:a pcm_s16le "$D/$1.wav"; }
say_clip short  "The quick brown fox jumps over the lazy dog."
say_clip medium "Please move the meeting to Thursday afternoon. I will send the updated agenda tonight. Let me know if the new time works for the whole team."
say_clip long   "Please move the meeting to Thursday afternoon. I will send the updated agenda tonight. Let me know if the new time works for the whole team. We finished the first version of the report and the numbers look good. The main risk is the delivery date, so I would like to review the plan again on Monday. After that we can share the results with the other teams and collect their feedback before the end of the month."
echo "machine: $(sysctl -n hw.model), $(sysctl -n machdep.cpu.brand_string), $(( $(sysctl -n hw.memsize) / 1073741824 )) GB RAM, macOS $(sw_vers -productVersion)"
for c in short medium long; do
  echo "== $c"
  /usr/bin/time -l "$BIN" --bench "$D/$c.wav" 5 2>&1 | grep -E "clip_seconds|run[0-9]_ms|maximum resident"
done
rm -rf "$D"
