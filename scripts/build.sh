#!/usr/bin/env bash
set -euo pipefail

echo "[TapSphere] Building native macOS menu bar application..."

mkdir -p bin scratch

# Create VFS overlay to bypass duplicate system modulemap conflict in CommandLineTools
cat << 'VFS' > scratch/vfs.yaml
version: 0
case-sensitive: false
roots:
  - name: "/Library/Developer/CommandLineTools/usr/include/swift/module.modulemap"
    type: "file"
    external-contents: "/dev/null"
VFS

SDK_PATH=$(xcrun --show-sdk-path)
TARGET="arm64-apple-macosx14.0"

# Compile TapSphere App Executable
swiftc -sdk "$SDK_PATH" \
  -target "$TARGET" \
  -vfsoverlay scratch/vfs.yaml \
  -parse-as-library \
  Sources/SonicFieldKit/Audio/*.swift \
  Sources/SonicFieldKit/Diagnostics/*.swift \
  Sources/SonicFieldKit/DSP/*.swift \
  Sources/SonicFieldKit/Detection/*.swift \
  Sources/SonicFieldKit/Localization/*.swift \
  Sources/SonicFieldKit/Calibration/*.swift \
  Sources/SonicFieldKit/Actions/*.swift \
  Sources/SonicFieldKit/Evaluation/*.swift \
  Sources/SonicFieldKit/App/AppState.swift \
  Sources/SonicFieldKit/Visualization/*.swift \
  Sources/TapSphereKit/*.swift \
  Sources/TapSphereKit/UI/*.swift \
  Sources/TapSphereApp/*.swift \
  -o bin/TapSphere

echo "[TapSphere] Built executable: bin/TapSphere"
