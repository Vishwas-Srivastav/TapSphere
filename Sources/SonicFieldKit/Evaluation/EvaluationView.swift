import SwiftUI

/// View for running empirical classification benchmarks and displaying confusion matrices.
public struct EvaluationView: View {
    @ObservedObject var appState: AppState
    @State private var runner = EvaluationRunner()
    @State private var selectedGroundTruth: Direction = .front
    @State private var report: EvaluationReport?

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Evaluation & Benchmark Suite")
                        .font(.system(size: 24, weight: .bold))
                    Text("Empirical accuracy measurement, confusion matrix analysis, and false positive metrics.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Divider()

                // Test Controls
                HStack(spacing: 16) {
                    Text("Ground Truth Zone:")
                        .fontWeight(.medium)

                    Picker("Zone", selection: $selectedGroundTruth) {
                        ForEach(Direction.allEightZones, id: \.self) { z in
                            Text(z.rawValue).tag(z)
                        }
                    }
                    .pickerStyle(.menu)

                    Button("Record Test Sample") {
                        runner.recordSample(actual: selectedGroundTruth, predicted: appState.currentPrediction)
                        report = runner.generateReport()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Clear Benchmarks") {
                        runner.clear()
                        report = nil
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)

                // Results Summary
                if let rep = report {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Benchmark Results Summary")
                            .font(.headline)

                        HStack(spacing: 24) {
                            VStack {
                                Text("TOTAL SAMPLES")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(rep.totalSamples)")
                                    .font(.title)
                                    .fontWeight(.bold)
                            }
                            VStack {
                                Text("ACCURACY")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(Int(rep.accuracy * 100))%")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                            VStack {
                                Text("UNKNOWN RATE")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(Int(rep.unknownRate * 100))%")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                            }
                        }

                        Divider()

                        Text("Per-Zone Accuracy")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
                            ForEach(rep.perZoneAccuracy.sorted(by: { $0.key.rawValue < $1.key.rawValue }), id: \.key) { zone, acc in
                                GridRow {
                                    Text(zone.rawValue)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                    Text("\(Int(acc * 100))%")
                                        .font(.caption)
                                        .monospacedDigit()
                                }
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(10)
                }
            }
            .padding(24)
        }
    }
}
