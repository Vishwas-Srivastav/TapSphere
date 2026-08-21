import SwiftUI

/// Phase 0 & 1 Diagnostic view for Core Audio capability discovery, real-time RMS, waveform, and channel correlation.
public struct AudioDiagnosticsView: View {
    @ObservedObject var appState: AppState
    @State private var exportedReportText: String?
    @State private var showExportSheet: Bool = false

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Mac Audio Diagnostic")
                            .font(.system(size: 24, weight: .bold))
                        Text("Inspect built-in audio hardware, real-time RMS, stream formats, and channel correlation.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(action: {
                        if appState.isCapturing {
                            appState.stopCapture()
                        } else {
                            appState.startCapture()
                        }
                    }) {
                        HStack {
                            Image(systemName: appState.isCapturing ? "stop.fill" : "play.fill")
                            Text(appState.isCapturing ? "Stop Capture" : "Start Real-Time Stream")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(appState.isCapturing ? .red : .blue)
                }

                Divider()

                // Permission Warning Card if not authorized
                if appState.permissionStatus != .authorized {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Microphone permission required for audio capture.")
                            .font(.body)
                        Spacer()
                        Button("Grant Permission") {
                            Task {
                                _ = await MicrophonePermission.shared.requestPermission()
                                appState.refreshHardwareInfo()
                            }
                        }
                    }
                    .padding()
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(8)
                }

                // 1. Hardware Device Info Card
                if let dev = appState.selectedDevice {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Audio Device Info")
                            .font(.headline)

                        Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 8) {
                            GridRow {
                                Text("Device Name:")
                                    .fontWeight(.medium)
                                Text(dev.name)
                            }
                            GridRow {
                                Text("Input Channels:")
                                    .fontWeight(.medium)
                                Text("\(dev.inputChannelCount)")
                            }
                            GridRow {
                                Text("Sample Rate:")
                                    .fontWeight(.medium)
                                Text("\(Int(dev.sampleRate)) Hz")
                            }
                            GridRow {
                                Text("Stream Format:")
                                    .fontWeight(.medium)
                                Text(dev.formatDescription)
                            }
                            GridRow {
                                Text("Built-in Mic:")
                                    .fontWeight(.medium)
                                Text(dev.isBuiltInMic ? "Yes (Apple Silicon Mic Array)" : "No")
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(10)
                }

                // 2. Real-Time RMS & Peak Meters
                VStack(alignment: .leading, spacing: 12) {
                    Text("Real-Time Channel Meters")
                        .font(.headline)

                    if appState.currentRMS.isEmpty {
                        Text("Start recording capture to view live RMS levels...")
                            .foregroundColor(.secondary)
                            .italic()
                            .padding(.vertical, 8)
                    } else {
                        ForEach(0..<appState.currentRMS.count, id: \.self) { idx in
                            let rms = appState.currentRMS[idx]
                            let peak = idx < appState.currentPeak.count ? appState.currentPeak[idx] : 0.0

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Channel \(idx + 1)")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Text("RMS: \(String(format: "%.4f", rms))  |  Peak: \(String(format: "%.4f", peak))")
                                        .font(.caption)
                                        .monospacedDigit()
                                        .foregroundColor(.secondary)
                                }

                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(height: 12)

                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(rms > 0.05 ? Color.green : Color.blue)
                                            .frame(width: max(0, min(geo.size.width, CGFloat(rms * 10) * geo.size.width)), height: 12)
                                    }
                                }
                                .frame(height: 12)
                            }
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)

                // 3. Channel Pairwise Correlation Matrix
                if !appState.correlationMatrix.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Channel Cross-Correlation Matrix")
                            .font(.headline)

                        Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 8) {
                            ForEach(appState.correlationMatrix.sorted(by: { $0.key < $1.key }), id: \.key) { pair, val in
                                GridRow {
                                    Text(pair)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text(String(format: "%.4f", val))
                                        .font(.subheadline)
                                        .monospacedDigit()
                                        .foregroundColor(val > 0.85 ? .blue : .purple)
                                }
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(10)
                }

                // 4. Export Buttons
                HStack(spacing: 12) {
                    Button(action: exportMarkdownReport) {
                        Label("Export Markdown Report", systemImage: "doc.text.fill")
                    }

                    Button(action: exportJSONReport) {
                        Label("Export JSON Report", systemImage: "arrow.down.doc.fill")
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding(24)
        }
    }

    private func exportMarkdownReport() {
        guard let dev = appState.selectedDevice else { return }
        let report = DiagnosticReportGenerator.generateReport(
            device: dev,
            rms: appState.currentRMS,
            peak: appState.currentPeak,
            correlationMatrix: appState.correlationMatrix
        )
        let md = DiagnosticReportGenerator.exportMarkdown(report: report)
        print("--- Diagnostic Report (Markdown) ---\n\(md)")
    }

    private func exportJSONReport() {
        guard let dev = appState.selectedDevice else { return }
        let report = DiagnosticReportGenerator.generateReport(
            device: dev,
            rms: appState.currentRMS,
            peak: appState.currentPeak,
            correlationMatrix: appState.correlationMatrix
        )
        if let json = try? DiagnosticReportGenerator.exportJSON(report: report) {
            print("--- Diagnostic Report (JSON) ---\n\(json)")
        }
    }
}
