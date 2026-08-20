import SwiftUI

/// Preferences & Settings view for TapSphere.
public struct PreferencesView: View {
    @ObservedObject var engine: TapActionEngine
    @State private var actionLeftFront: TriggerAction = .toggleMute
    @State private var actionLeftRear: TriggerAction = .none
    @State private var actionRightFront: TriggerAction = .takeScreenshot
    @State private var actionRightRear: TriggerAction = .launchApp(name: "Calculator")

    public init(engine: TapActionEngine) {
        self.engine = engine
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TapSphere Preferences")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Convert desk taps around your MacBook into instant macOS shortcuts.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Toggle("TapSphere Active", isOn: $engine.isEnabled)
                        .toggleStyle(.switch)
                        .onChange(of: engine.isEnabled) { _, newValue in
                            if newValue {
                                engine.start()
                            } else {
                                engine.stop()
                            }
                        }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)

                // Quadrant Action Mappings
                VStack(alignment: .leading, spacing: 12) {
                    Text("Desk Quadrant Action Mappings")
                        .font(.headline)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        quadrantCard(quadrant: .leftRear, binding: $actionLeftRear)
                        quadrantCard(quadrant: .rightRear, binding: $actionRightRear)
                        quadrantCard(quadrant: .leftFront, binding: $actionLeftFront)
                        quadrantCard(quadrant: .rightFront, binding: $actionRightFront)
                    }
                }

                // Audio & Sensitivity Controls
                VStack(alignment: .leading, spacing: 12) {
                    Text("Feedback & Sensitivity")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 16) {
                        Toggle("Play Audio Feedback Sound on Tap", isOn: $engine.playSoundFeedback)

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Tap Sensitivity Threshold")
                                Spacer()
                                Text(String(format: "%.1f", engine.sensitivityThreshold))
                                    .font(.caption)
                                    .fontWeight(.bold)
                            }
                            Slider(value: $engine.sensitivityThreshold, in: 3.0...10.0, step: 0.5)
                        }
                    }
                    .padding(16)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                }

                // Activity History Log
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Tap Triggers")
                        .font(.headline)

                    if engine.appState.actionManager.recentTapEvents.isEmpty {
                        Text("No desk taps recorded yet. Tap the desk near your MacBook surface to trigger.")
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(engine.appState.actionManager.recentTapEvents) { event in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)

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
            }
            .padding(24)
        }
        .frame(minWidth: 700, minHeight: 550)
        .onAppear {
            syncState()
        }
    }

    private func quadrantCard(quadrant: LaptopQuadrant, binding: Binding<TriggerAction>) -> some View {
        let isCurrent = (engine.activeQuadrant == quadrant)
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
                engine.appState.actionManager.setAction(newValue, for: quadrant)
            }

            Button(action: {
                engine.appState.actionManager.dispatchTap(quadrant: quadrant)
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
        actionLeftFront = engine.appState.actionManager.getAction(for: .leftFront)
        actionLeftRear = engine.appState.actionManager.getAction(for: .leftRear)
        actionRightFront = engine.appState.actionManager.getAction(for: .rightFront)
        actionRightRear = engine.appState.actionManager.getAction(for: .rightRear)
    }
}
