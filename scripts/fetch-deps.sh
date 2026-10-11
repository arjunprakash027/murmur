#!/bin/bash
# Downloads what a source build needs: the whisper.cpp XCFramework and the base.en model.
set -euo pipefail
cd "$(dirname "$0")/.."
FW_VERSION=v1.7.5
FW_SHA=c7faeb328620d6012e130f3d705c51a6ea6c995605f2df50f6e1ad68c59c6c4a
mkdir -p vendor/xcframework models
if [ ! -d vendor/xcframework/unpacked/build-apple/whisper.xcframework ]; then
  curl -fL -o vendor/xcframework/fw.zip "https://github.com/ggml-org/whisper.cpp/releases/download/$FW_VERSION/whisper-$FW_VERSION-xcframework.zip"
  [ "$(swift package compute-checksum vendor/xcframework/fw.zip)" = "$FW_SHA" ] || { echo "checksum mismatch" >&2; exit 1; }
  unzip -q vendor/xcframework/fw.zip -d vendor/xcframework/unpacked
  rm vendor/xcframework/fw.zip
fi
[ -f models/ggml-base.en.bin ] || curl -fL -o models/ggml-base.en.bin https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin
echo "deps ready"
