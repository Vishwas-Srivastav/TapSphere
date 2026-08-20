import SwiftUI

/// Configurator view for mapping laptop surface quadrant taps to native macOS actions.
public struct ActionConfigView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedActionLeftFront: TriggerAction = .toggleMute
    @State private var selectedActionLeftRear: TriggerAction = .none
    @State private var selectedActionRightFront: TriggerAction = .takeScreenshot
    @State private var selectedActionRightRear: TriggerAction = .launchApp(name: "Calculator")
    @State private var customCommand: String = "say 'Tap detected on SonicField'"

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Acoustic Tap Action Configurator")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Map physical desk taps around your MacBook to automated macOS actions (e.g. Right Front tap -> Take Screenshot).")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Surface Quadrant Card Grid
                VStack(alignment: .leading, spacing: 12) {
                    Text("Surface Quadrant Mappings")
                        .font(.headline)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        quadrantCard(quadrant: .leftRear, binding: $selectedActionLeftRear)
                        quadrantCard(quadrant: .rightRear, binding: $selectedActionRightRear)
                        quadrantCard(quadrant: .leftFront, binding: $selectedActionLeftFront)
                        quadrantCard(quadrant: .rightFront, binding: $selectedActionRightFront)
                    }
                }

                // Recent Tap Events Log
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Tap Trigger Activity")
                        .font(.headline)

                    if appState.actionManager.recentTapEvents.isEmpty {
                        Text("No desk taps detected yet. Tap the desk near your MacBook surface to test.")
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(appState.actionManager.recentTapEvents) { event in
                                HStack {
                                    Image(systemName: event.isSuccess ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                        .foregroundColor(event.isSuccess ? .green : .red)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(event.quadrant.description)")
                                            .font(.body)
                                            .fontWeight(.semibold)
                                        Text(event.actionExecuted)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Text(event.timestamp, style: .time)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .padding(10)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(8)
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding(24)
        }
        .onAppear {
            syncState()
        }
    }

    private func quadrantCard(quadrant: LaptopQuadrant, binding: Binding<TriggerAction>) -> some View {
        let isCurrent = (appState.currentQuadrant == quadrant)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(quadrant.rawValue)
                    .font(.headline)
                Spacer()
                if isCurrent {
                    Text("ACTIVE")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.2))
                        .foregroundColor(.accentColor)
                        .cornerRadius(4)
                }
            }

            Text(quadrant.description)
                .font(.caption)
                .foregroundColor(.secondary)

            Picker("Action", selection: binding) {
                Text("Take Screenshot").tag(TriggerAction.takeScreenshot)
                Text("Toggle Input Mute").tag(TriggerAction.toggleMute)
                Text("Launch Calculator").tag(TriggerAction.launchApp(name: "Calculator"))
                Text("Launch Terminal").tag(TriggerAction.launchApp(name: "Terminal"))
                Text("None (Disabled)").tag(TriggerAction.none)
            }
            .pickerStyle(.menu)
            .onChange(of: binding.wrappedValue) { _, newValue in
                appState.actionManager.setAction(newValue, for: quadrant)
            }

            Button(action: {
                appState.actionManager.dispatchTap(quadrant: quadrant)
            }) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Test Action")
                }
                .font(.caption)
            }
            .buttonStyle(.bordered)
        }
        .padding(16)
        .background(isCurrent ? Color.accentColor.opacity(0.1) : Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrent ? Color.accentColor : Color.gray.opacity(0.2), lineWidth: isCurrent ? 2 : 1)
        )
    }

    private func syncState() {
        selectedActionLeftFront = appState.actionManager.getAction(for: .leftFront)
        selectedActionLeftRear = appState.actionManager.getAction(for: .leftRear)
        selectedActionRightFront = appState.actionManager.getAction(for: .rightFront)
        selectedActionRightRear = appState.actionManager.getAction(for: .rightRear)
    }
}
