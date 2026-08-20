import Foundation
import AppKit

/// Manages configurable spatial tap actions, JSON persistence, and native macOS execution.
public final class ActionManager: @unchecked Sendable {
    public static let shared = ActionManager()

    private let fileManager = FileManager.default
    private let lock = NSLock()

    public private(set) var quadrantActions: [LaptopQuadrant: TriggerAction] = [
        .rightFront: .takeScreenshot,
        .leftFront: .toggleMute,
        .rightRear: .launchApp(name: "Calculator"),
        .leftRear: .none
    ]

    public private(set) var recentTapEvents: [TapEventRecord] = []

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
        lock.lock()
        quadrantActions[quadrant] = action
        lock.unlock()
        saveConfig()
    }

    public func getAction(for quadrant: LaptopQuadrant) -> TriggerAction {
        lock.lock()
        defer { lock.unlock() }
        return quadrantActions[quadrant] ?? .none
    }

    @discardableResult
    public func dispatchTap(quadrant: LaptopQuadrant) -> TapEventRecord? {
        guard quadrant != .unknown else { return nil }
        let action = getAction(for: quadrant)
        guard action != .none else { return nil }

        let success = execute(action: action)
        let record = TapEventRecord(
            quadrant: quadrant,
            actionExecuted: action.description,
            isSuccess: success
        )

        lock.lock()
        recentTapEvents.insert(record, at: 0)
        if recentTapEvents.count > 20 {
            recentTapEvents.removeLast()
        }
        lock.unlock()

        return record
    }

    private func execute(action: TriggerAction) -> Bool {
        switch action {
        case .takeScreenshot:
            let desktop = fileManager.urls(for: .desktopDirectory, in: .userDomainMask).first!
            let timestamp = Int(Date().timeIntervalSince1970)
            let fileURL = desktop.appendingPathComponent("SonicField_Screenshot_\(timestamp).png")
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
            process.arguments = ["-x", fileURL.path]
            do {
                try process.run()
                return true
            } catch {
                return false
            }

        case .toggleMute:
            let script = "set curVol to input volume of (get volume settings)\nif curVol is 0 then\nset volume input volume 100\nelse\nset volume input volume 0\nend if"
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = ["-e", script]
            do {
                try process.run()
                return true
            } catch {
                return false
            }

        case .launchApp(let name):
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            process.arguments = ["-a", name]
            do {
                try process.run()
                return true
            } catch {
                return false
            }

        case .runShellScript(let command):
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-c", command]
            do {
                try process.run()
                return true
            } catch {
                return false
            }

        case .none:
            return true
        }
    }

    public func saveConfig() {
        lock.lock()
        let stringKeyedDict = Dictionary(uniqueKeysWithValues: quadrantActions.map { ($0.key.rawValue, $0.value) })
        lock.unlock()

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
            lock.lock()
            self.quadrantActions = loadedDict
            lock.unlock()
        } catch {
            print("Failed to load ActionConfig: \(error)")
        }
    }
}
