import SwiftUI

/// Main UI container with tab bar navigation across Diagnostic, Spatial Radar, Calibration, Actions, and Benchmark modes.
public struct MainView: View {
    @StateObject private var appState = AppState()

    public init() {}

    public var body: some View {
        TabView(selection: $appState.selectedTab) {
            AudioDiagnosticsView(appState: appState)
                .tabItem {
                    Label("Diagnostics", systemImage: "waveform.path.ecg")
                }
                .tag(0)

            SpatialFieldView(appState: appState)
                .tabItem {
                    Label("Spatial Radar", systemImage: "macbook.and.iphone")
                }
                .tag(1)

            CalibrationView(appState: appState)
                .tabItem {
                    Label("Calibration", systemImage: "slider.horizontal.3")
                }
                .tag(2)

            ActionConfigView()
                .environmentObject(appState)
                .tabItem {
                    Label("Actions", systemImage: "bolt.horizontal.fill")
                }
                .tag(3)

            EvaluationView(appState: appState)
                .tabItem {
                    Label("Evaluation", systemImage: "chart.bar.xaxis")
                }
                .tag(4)
        }
        .frame(minWidth: 920, minHeight: 670)
    }
}
