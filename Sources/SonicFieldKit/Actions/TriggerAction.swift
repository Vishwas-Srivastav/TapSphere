import Foundation

/// Configurable macOS actions triggered by spatial desk tap events.
public enum TriggerAction: Codable, Sendable, Equatable, Hashable, Identifiable, CustomStringConvertible {
    case takeScreenshot
    case toggleMute
    case launchApp(name: String)
    case runShellScript(command: String)
    case none

    public var id: String { description }

    public var description: String {
        switch self {
        case .takeScreenshot:
            return "Take Screenshot (Saved to Desktop)"
        case .toggleMute:
            return "Toggle Audio Input Mute"
        case .launchApp(let name):
            return "Launch App (\(name))"
        case .runShellScript(let cmd):
            return "Run Script (\(cmd))"
        case .none:
            return "No Action (Disabled)"
        }
    }

    public static var allPresetActions: [TriggerAction] {
        [
            .takeScreenshot,
            .toggleMute,
            .launchApp(name: "Calculator"),
            .launchApp(name: "Terminal"),
            .none
        ]
    }
}

/// Record of an executed acoustic tap event.
public struct TapEventRecord: Identifiable, Codable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let quadrant: LaptopQuadrant
    public let actionExecuted: String
    public let isSuccess: Bool

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        quadrant: LaptopQuadrant,
        actionExecuted: String,
        isSuccess: Bool
    ) {
        self.id = id
        self.timestamp = timestamp
        self.quadrant = quadrant
        self.actionExecuted = actionExecuted
        self.isSuccess = isSuccess
    }
}
