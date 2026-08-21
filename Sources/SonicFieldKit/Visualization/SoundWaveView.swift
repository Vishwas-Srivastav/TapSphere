import SwiftUI

/// Animated sound wave arcs radiating inward from the detected directional zone.
public struct SoundWaveView: View {
    public let direction: Direction
    public let active: Bool

    @State private var phase: CGFloat = 0.0

    public init(direction: Direction, active: Bool) {
        self.direction = direction
        self.active = active
    }

    public var body: some View {
        GeometryReader { geo in
            if active, let angle = direction.centerAngleDegrees {
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                let radius = min(geo.size.width, geo.size.height) * 0.35

                Canvas { context, size in
                    let radians = (angle - 90.0) * .pi / 180.0
                    let endPoint = CGPoint(
                        x: center.x + cos(radians) * radius,
                        y: center.y + sin(radians) * radius
                    )

                    for i in 1...4 {
                        let stepRadius = CGFloat(i) * 12.0 + phase
                        var path = Path()
                        path.addArc(
                            center: endPoint,
                            radius: stepRadius,
                            startAngle: .degrees(angle + 120),
                            endAngle: .degrees(angle + 240),
                            clockwise: false
                        )

                        let alpha = max(0.1, 1.0 - (stepRadius / 60.0))
                        context.stroke(
                            path,
                            with: .color(Color.green.opacity(alpha)),
                            lineWidth: 3
                        )
                    }
                }
                .onAppear {
                    withAnimation(Animation.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                        phase = 16.0
                    }
                }
            }
        }
    }
}
