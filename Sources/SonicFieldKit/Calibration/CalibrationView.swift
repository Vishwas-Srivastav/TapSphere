import SwiftUI

/// Guided wizard view for calibrating 4-zone or 8-zone profiles for specific rooms & MacBook positions.
public struct CalibrationView: View {
    @ObservedObject var appState: AppState

    @State private var profileName: String = "My Desk Setup"
    @State private var currentZoneIndex: Int = 0
    @State private var isRecordingSample: Bool = false
    @State private var progress: Double = 0.0
    @State private var currentProfile: CalibrationProfile = CalibrationProfile()
    @State private var timer: Timer?

    private var targetZones: [Direction] {
        [.front, .frontRight, .right, .rearRight, .rear, .rearLeft, .left, .frontLeft]
    }

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Room & Laptop Calibration Wizard")
                        .font(.system(size: 24, weight: .bold))
                    Text("Calibrate SonicField for your room acoustics, desk surface, and laptop positioning.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Divider()

                // Profile Configuration Card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Profile Configuration")
                        .font(.headline)

                    HStack {
                        Text("Profile Name:")
                            .fontWeight(.medium)
                        TextField("Profile Name", text: $profileName)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 240)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)

                // Active Calibration Zone Step
                if currentZoneIndex < targetZones.count {
                    let targetZone = targetZones[currentZoneIndex]

                    VStack(spacing: 16) {
                        Text("STEP \(currentZoneIndex + 1) OF \(targetZones.count)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)

                        Text("Position Yourself At: \(targetZone.rawValue)")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Stand approx. 1 meter away from your MacBook and speak naturally for 5 seconds (e.g. \"Hello, testing calibration\").")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: 480)

                        ProgressView(value: progress, total: 1.0)
                            .progressViewStyle(.linear)
                            .frame(width: 320)

                        Button(action: startZoneRecording) {
                            HStack {
                                Image(systemName: isRecordingSample ? "mic.fill" : "record.circle")
                                Text(isRecordingSample ? "Recording Sample..." : "Record Zone Sample")
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isRecordingSample)
                    }
                    .padding(32)
                    .frame(maxWidth: .infinity)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                } else {
                    // Calibration Complete
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.green)

                        Text("Calibration Profile Complete!")
                            .font(.title)
                            .fontWeight(.bold)

                        Button("Save & Activate Profile") {
                            currentProfile = CalibrationProfile(
                                name: profileName,
                                isEightZone: true,
                                zoneSamples: currentProfile.zoneSamples
                            )
                            try? CalibrationManager.shared.saveProfile(currentProfile)
                            appState.refreshHardwareInfo()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(32)
                    .frame(maxWidth: .infinity)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                }
            }
            .padding(24)
        }
    }

    private func startZoneRecording() {
        guard !isRecordingSample else { return }
        isRecordingSample = true
        progress = 0.0
        appState.startCapture()

        let targetZone = targetZones[currentZoneIndex]
        var collectedFeatures: [FeatureVector] = []

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { t in
            Task { @MainActor in
                progress += 0.02
                if let frame = appState.lastAudioFrame {
                    let features = appState.featureExtractor.extractFeatures(from: frame)
                    collectedFeatures.append(features)
                }

                if progress >= 1.0 {
                    t.invalidate()
                    isRecordingSample = false
                    currentProfile.zoneSamples[targetZone] = collectedFeatures
                    currentZoneIndex += 1
                }
            }
        }
    }
}
