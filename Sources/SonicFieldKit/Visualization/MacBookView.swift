import SwiftUI

/// Vector SwiftUI view representing a MacBook laptop at the origin of the spatial field.
public struct MacBookView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 2) {
            // Screen
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(NSColor.darkGray))
                    .frame(width: 80, height: 52)

                RoundedRectangle(cornerRadius: 4)
                    .fill(LinearGradient(gradient: Gradient(colors: [.blue.opacity(0.6), .cyan.opacity(0.8)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 72, height: 44)

                Image(systemName: "laptopcomputer")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.9))
            }

            // Keyboard Base
            ZStack {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(NSColor.lightGray))
                    .frame(width: 96, height: 8)

                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 24, height: 2)
                    .offset(y: 2)
            }
        }
    }
}
