import Foundation

/// Manages interactive calibration sessions, sample collection, and profile disk persistence.
public final class CalibrationManager: @unchecked Sendable {
    public static let shared = CalibrationManager()

    private let fileManager = FileManager.default
    private let lock = NSLock()

    public init() {}

    private var profilesDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("SonicField/Profiles", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Saves a calibration profile to disk.
    public func saveProfile(_ profile: CalibrationProfile) throws {
        lock.lock()
        defer { lock.unlock() }

        let fileURL = profilesDirectory.appendingPathComponent("\(profile.id.uuidString).json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(profile)
        try data.write(to: fileURL, options: .atomic)
    }

    /// Loads all stored calibration profiles from disk.
    public func loadAllProfiles() -> [CalibrationProfile] {
        lock.lock()
        defer { lock.unlock() }

        guard let files = try? fileManager.contentsOfDirectory(at: profilesDirectory, includingPropertiesForKeys: nil) else {
            return []
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        var profiles: [CalibrationProfile] = []

        for url in files where url.pathExtension == "json" {
            if let data = try? Data(contentsOf: url),
               let profile = try? decoder.decode(CalibrationProfile.self, from: data) {
                profiles.append(profile)
            }
        }
        return profiles.sorted(by: { $0.createdAt > $1.createdAt })
    }

    /// Deletes a calibration profile.
    public func deleteProfile(id: UUID) {
        lock.lock()
        defer { lock.unlock() }
        let fileURL = profilesDirectory.appendingPathComponent("\(id.uuidString).json")
        try? fileManager.removeItem(at: fileURL)
    }
}
