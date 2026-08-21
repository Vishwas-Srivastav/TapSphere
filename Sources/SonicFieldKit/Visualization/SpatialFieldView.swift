import SwiftUI

/// Spatial awareness field visualizer mapping 8 directional zones and 4 laptop surface quadrants around the MacBook.
public struct SpatialFieldView: View {
    @ObservedObject var appState: AppState
    @State private var isEightZoneMode: Bool = true

    public init(appState: AppState) {
        self.appState = appState
    }

    private var activeZones: [Direction] {
        isEightZoneMode ? Direction.allEightZones : Direction.primaryFourZones
    }

    public var body: some View {
        VStack(spacing: 16) {
            // Header Controls
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SonicField Radar")
                        .font(.system(size: 24, weight: .bold))
                    Text("Real-time 360° speech localization & laptop surface quadrant field.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()

                Picker("Resolution", selection: $isEightZoneMode) {
                    Text("4 Zones").tag(false)
                    Text("8 Zones").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            Divider()

            // Radar Visualizer Canvas
            ZStack {
                // Background radial circles
                Circle()
                    .stroke(Color.gray.opacity(0.15), lineWidth: 2)
                    .frame(width: 320, height: 320)

                Circle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                    .frame(width: 220, height: 220)

                // Direction Sector Wedges
                ForEach(activeZones, id: \.self) { zone in
                    ZoneWedgeView(
                        zone: zone,
                        isSelected: appState.currentPrediction.direction == zone,
                        confidence: appState.currentPrediction.confidence
                    )
                }

                // Sound Wave Animation Overlay
                SoundWaveView(
                    direction: appState.currentPrediction.direction,
                    active: appState.isSpeechDetected && appState.currentPrediction.direction != .unknown
                )
                .frame(width: 360, height: 360)

                // Center MacBook Icon
                MacBookView()
            }
            .frame(width: 340, height: 340)

            // Dynamic Prediction & Surface Quadrant Status Card
            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("DETECTED DIRECTION")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Text(appState.currentPrediction.direction.rawValue)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(appState.currentPrediction.direction == .unknown ? .orange : .green)
                }

                VStack(spacing: 4) {
                    Text("LAPTOP QUADRANT")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Text(appState.currentQuadrant.rawValue)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.accentColor)
                }

                VStack(spacing: 4) {
                    Text("CONFIDENCE")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Text("\(Int(appState.currentPrediction.confidence * 100))%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }

                VStack(spacing: 4) {
                    Text("SPEECH SIGNAL")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Text(appState.isSpeechDetected ? "ACTIVE" : "IDLE")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(appState.isSpeechDetected ? .green : .gray)
                }
            }
            .padding(12)
            .frame(maxWidth: 620)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            .padding(.bottom, 16)
        }
    }
}

/// Helper view for rendering sector wedges around the radar circle.
struct ZoneWedgeView: View {
    let zone: Direction
    let isSelected: Bool
    let confidence: Float

    var body: some View {
        GeometryReader { geo in
            if let angle = zone.centerAngleDegrees {
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                let radius: CGFloat = 145.0
                let radians = (angle - 90.0) * .pi / 180.0
                let point = CGPoint(
                    x: center.x + cos(radians) * radius,
                    y: center.y + sin(radians) * radius
                )

                ZStack {
                    Circle()
                        .fill(isSelected ? Color.green.opacity(0.35) : Color.blue.opacity(0.08))
                        .frame(width: isSelected ? 50 : 42, height: isSelected ? 50 : 42)
                        .scaleEffect(isSelected ? 1.15 : 1.0)
                        .animation(.spring(response: 0.3), value: isSelected)

                    Text(zone.rawValue)
                        .font(.system(size: 9, weight: isSelected ? .bold : .medium))
                        .foregroundColor(isSelected ? .green : .primary)
                }
                .position(point)
            }
        }
    }
}
