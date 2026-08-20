import SwiftUI

@main
struct TapSphereApp: App {
    @StateObject private var engine = TapActionEngine()
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        MenuBarExtra("TapSphere", systemImage: engine.isEnabled ? "hand.tap.fill" : "hand.tap") {
            VStack {
                Text("TapSphere macOS")
                    .font(.headline)

                Divider()

                Button(engine.isEnabled ? "Pause Tap Detection" : "Resume Tap Detection") {
                    engine.toggleEnabled()
                }

                if engine.activeQuadrant != .unknown {
                    Text("Active Quadrant: \(engine.activeQuadrant.rawValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                Button("Preferences...") {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "preferences")
                }

                Divider()

                Button("Quit TapSphere") {
                    NSApp.terminate(nil)
                }
            }
        }

        Window("TapSphere Preferences", id: "preferences") {
            PreferencesView(engine: engine)
        }
        .windowResizability(.contentSize)
    }
}
