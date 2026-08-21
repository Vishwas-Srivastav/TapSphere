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

    /// Generates a default baseline calibration profile with synthetic spatial centroids.
    public static func defaultBaselineProfile() -> CalibrationProfile {
        let sampleDate = Date()
        
        func makeSample(rms: Float, peak: Float, zcr: Float, centroid: Float, rolloff: Float, leftRatio: Float, rightRatio: Float) -> FeatureVector {
            FeatureVector(
                timestamp: sampleDate,
                rms: rms,
                peak: peak,
                zeroCrossingRate: zcr,
                spectralCentroid: centroid,
                spectralRolloff: rolloff,
                bandEnergies: [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8],
                mfccs: [Float](repeating: 0.1, count: 12),
                channelEnergyRatios: [leftRatio, rightRatio],
                pairwiseCorrelations: [0.85]
            )
        }

        let samples: [Direction: [FeatureVector]] = [
            .frontLeft: [makeSample(rms: 0.05, peak: 0.30, zcr: 0.08, centroid: 2500.0, rolloff: 4500.0, leftRatio: 0.65, rightRatio: 0.35)],
            .frontRight: [makeSample(rms: 0.05, peak: 0.30, zcr: 0.15, centroid: 2600.0, rolloff: 4600.0, leftRatio: 0.35, rightRatio: 0.65)],
            .rearLeft: [makeSample(rms: 0.08, peak: 0.45, zcr: 0.10, centroid: 4200.0, rolloff: 7000.0, leftRatio: 0.65, rightRatio: 0.35)],
            .rearRight: [makeSample(rms: 0.08, peak: 0.45, zcr: 0.18, centroid: 4400.0, rolloff: 7200.0, leftRatio: 0.35, rightRatio: 0.65)]
        ]

        return CalibrationProfile(
            name: "Default Factory Baseline Profile",
            zoneSamples: samples
        )
    }
}
