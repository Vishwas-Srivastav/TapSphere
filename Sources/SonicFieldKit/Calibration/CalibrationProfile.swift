import Foundation

/// Codable data structure for storing room/device calibration profiles.
public struct CalibrationProfile: Codable, Sendable, Identifiable {
    public let id: UUID
    public let name: String
    public let version: Int
    public let createdAt: Date
    public let deviceName: String
    public let sampleRate: Double
    public let channelCount: Int
    public let isEightZone: Bool
    public var baselineNoiseFloor: Float
    /// Map of directional zones to recorded feature vector training samples
    public var zoneSamples: [Direction: [FeatureVector]]
    /// Negative training samples (ambient noise, typing, mouse clicks)
    public var negativeSamples: [FeatureVector]

    public init(
        id: UUID = UUID(),
        name: String = "Default Profile",
        version: Int = 1,
        createdAt: Date = Date(),
        deviceName: String = "Built-in Microphone",
        sampleRate: Double = 48000.0,
        channelCount: Int = 1,
        isEightZone: Bool = false,
        baselineNoiseFloor: Float = 0.002,
        zoneSamples: [Direction: [FeatureVector]] = [:],
        negativeSamples: [FeatureVector] = []
    ) {
        self.id = id
        self.name = name
        self.version = version
        self.createdAt = createdAt
        self.deviceName = deviceName
        self.sampleRate = sampleRate
        self.channelCount = channelCount
        self.isEightZone = isEightZone
        self.baselineNoiseFloor = baselineNoiseFloor
        self.zoneSamples = zoneSamples
        self.negativeSamples = negativeSamples
    }

    /// Total count of training feature vectors collected across all zones.
    public var totalSampleCount: Int {
        let positive = zoneSamples.values.reduce(0) { $0 + $1.count }
        return positive + negativeSamples.count
    }
}
