# TapSphere

> Native macOS background menu bar application converting physical desk taps around your Apple Silicon MacBook into instant productivity shortcuts.

---

## Overview

**TapSphere** is an ambient macOS productivity utility built on top of `SonicFieldKit`. By analyzing real-time acoustic transients across your MacBook's built-in microphone array, TapSphere detects physical desk taps across **4 surface quadrants**:

```
                      Display Side (Hinge)
           ┌────────────────────────────────────────┐
  Left     │               [ MACBOOK ]              │    Right
  Rear     │                                        │    Rear
           ├────────────────────────────────────────┤
  Left     │                [ Trackpad ]            │    Right
  Front    │                                        │    Front
           └────────────────────────────────────────┘
                      Trackpad Side (User)
```

### Configurable Tap Shortcuts

- **Right Front Tap**: Instant Screenshot (saved to Desktop).
- **Left Front Tap**: Toggle Microphone Input Mute.
- **Right Rear Tap**: Quick App Launcher (Terminal, Calculator, Slack, Notes).
- **Left Rear Tap**: Custom Zsh Script / System Action Execution.

---

## Architecture

- **Menu Bar Extra (`NSStatusItem`)**: Runs silently in the macOS menu bar with zero dock clutter.
- **Acoustic Tap Detector (`TapDetector`)**: High-frequency transient onset detector ($\text{Peak}/\text{RMS} \ge 5.5$) distinguishing physical surface taps from voice speech.
- **Audio Feedback (`NSSound`)**: Plays subtle system click feedback when a desk tap is triggered.
- **Preferences UI**: SwiftUI settings dashboard for customizing action mappings, sensitivity thresholds, and sound feedback.

---

## Quick Start

### Prerequisites

- **macOS 14.0+** (macOS 15 Sequoia recommended)
- **Apple Silicon Mac** (M1/M2/M3/M4)

### 1. Build Executable

```bash
./scripts/build.sh
```

### 2. Run Guardrail Validation

```bash
./scripts/check-guardrails.sh
```

### 3. Launch TapSphere

```bash
./bin/TapSphere
```

---

## License

This project is licensed under the [MIT License](LICENSE).
