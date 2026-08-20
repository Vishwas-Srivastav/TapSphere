import Foundation
import AppKit
import Combine

/// Manages configurable spatial tap actions, JSON persistence, and non-blocking native macOS execution.
@MainActor
public final class ActionManager: ObservableObject {
    public static let shared = ActionManager()

    private let fileManager = FileManager.default
    private var lastDispatchTime: Date = .distantPast

    @Published public var quadrantActions: [LaptopQuadrant: TriggerAction] = [
        .leftFront: .toggleMute,
        .leftRear: .launchApp(name: "Calculator"),
        .rightFront: .none,
        .rightRear: .launchApp(name: "Terminal")
    ]

    @Published public var recentTapEvents: [TapEventRecord] = []

    private var configFileURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = appSupport.appendingPathComponent("SonicField", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("ActionConfig.json")
    }

    public init() {
        loadConfig()
    }

    public func setAction(_ action: TriggerAction, for quadrant: LaptopQuadrant) {
        quadrantActions[quadrant] = action
        saveConfig()
    }

    public func getAction(for quadrant: LaptopQuadrant) -> TriggerAction {
        return quadrantActions[quadrant] ?? .none
    }

    @discardableResult
    public func dispatchTap(quadrant: LaptopQuadrant) -> TapEventRecord? {
        let now = Date()
        guard now.timeIntervalSince(lastDispatchTime) >= 0.8 else { return nil }
        lastDispatchTime = now

        guard quadrant != .unknown else { return nil }
        let action = getAction(for: quadrant)
        guard action != .none else { return nil }

        let success = execute(action: action)
        let record = TapEventRecord(
            quadrant: quadrant,
            actionExecuted: action.description,
            isSuccess: success
        )

        recentTapEvents.insert(record, at: 0)
        if recentTapEvents.count > 20 {
            recentTapEvents.removeLast()
        }

        return record
    }

    private func execute(action: TriggerAction) -> Bool {
        // Execute asynchronously on background queue to prevent main thread blocking
        Task.detached(priority: .userInitiated) {
            switch action {
            case .takeScreenshot:
                let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
                let timestamp = Int(Date().timeIntervalSince1970)
                let fileURL = desktop.appendingPathComponent("SonicField_Screenshot_\(timestamp).png")
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
                process.arguments = ["-x", fileURL.path]
                do {
                    try process.run()
                    print("[ActionManager] 📸 Screenshot triggered: \(fileURL.path)")
                } catch {
                    print("[ActionManager] Screenshot failed: \(error)")
                }

            case .toggleMute:
                let script = "set curVol to input volume of (get volume settings)\nif curVol is 0 then\nset volume input volume 100\nelse\nset volume input volume 0\nend if"
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
                process.arguments = ["-e", script]
                do {
                    try process.run()
                    print("[ActionManager] 🎙️ Toggle Mute executed.")
                } catch {
                    print("[ActionManager] Toggle Mute failed: \(error)")
                }

            case .launchApp(let name):
                print("[ActionManager] 🚀 Launching App: \(name)")
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
                process.arguments = ["-a", name]
                do {
                    try process.run()
                } catch {
                    print("[ActionManager] App launch failed: \(error)")
                }

            case .runShellScript(let command):
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/bin/zsh")
                process.arguments = ["-c", command]
                do {
                    try process.run()
                    print("[ActionManager] 💻 Shell script executed: \(command)")
                } catch {
                    print("[ActionManager] Shell script failed: \(error)")
                }

            case .none:
                break
            }
        }
        return true
    }

    public func saveConfig() {
        let stringKeyedDict = Dictionary(uniqueKeysWithValues: quadrantActions.map { ($0.key.rawValue, $0.value) })

        do {
            let data = try JSONEncoder().encode(stringKeyedDict)
            try data.write(to: configFileURL)
        } catch {
            print("Failed to save ActionConfig: \(error)")
        }
    }

    public func loadConfig() {
        guard fileManager.fileExists(atPath: configFileURL.path) else { return }
        do {
            let data = try Data(contentsOf: configFileURL)
            let stringKeyedDict = try JSONDecoder().decode([String: TriggerAction].self, from: data)
            var loadedDict: [LaptopQuadrant: TriggerAction] = [:]
            for (key, val) in stringKeyedDict {
                if let quad = LaptopQuadrant(rawValue: key) {
                    loadedDict[quad] = val
                }
            }
            self.quadrantActions = loadedDict
        } catch {
            print("Failed to load ActionConfig: \(error)")
        }
    }
}
