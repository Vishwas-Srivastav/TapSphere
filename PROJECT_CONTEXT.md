# TapSphere — Project Context & Handoff Specification

## Product Vision
**TapSphere** is a native Apple Silicon macOS productivity application that converts physical desk taps around your MacBook (*Left Front*, *Left Rear*, *Right Front*, *Right Rear*) into automated shortcuts (e.g., Right Front tap -> Take Screenshot, Left Front tap -> Toggle Mute).

---

## Laptop Surface Geometry

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

---

## Codebase Location & Target Environment
- **Local Directory**: `/Users/vishwassrivastav/Desktop/Work/TapSphere`
- **Target OS**: macOS 14.0+ (macOS 15 Sequoia recommended)
- **Target Hardware**: Apple Silicon Mac (M1/M2/M3/M4)
- **Primary Branch**: `development`
- **Active Feature Branch**: `TS-01`

---

## Technical Architecture & Core Components

1. **`Sources/SonicFieldKit/`**
   - Core DSP and Audio Engine (`AudioDeviceInspector`, `AudioCaptureService`, `VoiceActivityDetector`, `vDSP` FFT, `DirectionClassifier`).

2. **`Sources/SonicFieldKit/Detection/TapDetector.swift`**
   - Transient acoustic onset detector calculating peak-to-RMS ratios ($\text{Peak}/\text{RMS} \ge 5.5$) to isolate physical desk surface impacts from voice speech.

3. **`Sources/SonicFieldKit/Actions/ActionManager.swift`**
   - Configurable macOS action dispatcher executing Screenshots (`/usr/sbin/screencapture`), Input Mute, App Launchers, and Zsh Scripts, with JSON persistence in `Application Support/SonicField/ActionConfig.json`.

4. **`Sources/TapSphereKit/TapActionEngine.swift`**
   - Central application coordinator listening to tap events, triggering native actions, playing audio feedback (`NSSound(named: "Tink")`), and managing engine state.

5. **`Sources/TapSphereKit/UI/PreferencesView.swift`**
   - SwiftUI Settings dashboard for configuring quadrant action mappings, sensitivity sliders ($3.0 \dots 10.0$), sound feedback toggles, and trigger logs.

6. **`Sources/TapSphereApp/TapSphereApp.swift`**
   - SwiftUI `@main` application using `MenuBarExtra` for status bar item navigation (*Pause/Resume*, *Active Quadrant Status*, *Preferences...*, *Quit*).

---

## Engineering Guardrail Protocol

- **Branch Naming**: `<PROJECT_INITIALS>-<NUMBER>` (e.g. `TS-01`, `TS-02`).
- **Commit Format**: [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `chore:`, `docs:`).
- **PR Description Format**: Must include `## Summary`, `## Why`, `## Testing`, `## Related Work`, and checked `Checklist`.
- **Build Script**: `./scripts/build.sh` (compiles native binary into `bin/TapSphere`).
- **Guardrails Script**: `./scripts/check-guardrails.sh`.

---

## Next Features on the Roadmap

1. **Launch at Login (`SMAppService`)**: Automatically launch TapSphere in the menu bar when your MacBook boots up.
2. **Interactive Desk Calibration Wizard**: Guided 3-step setup to calibrate peak-to-RMS tap sensitivity for your specific desk surface.
3. **Custom Feedback Audio & Haptics**: Selectable sound effects (*Tink*, *Pop*, *Subtle Haptic*, *Silence*).
4. **Global Hotkey Integration**: Support keyboard hotkey triggers alongside desk taps.
