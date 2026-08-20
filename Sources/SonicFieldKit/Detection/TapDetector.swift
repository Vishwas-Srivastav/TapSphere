import Foundation

/// Configuration options for physical desk tap / acoustic impact detection.
public struct TapDetectorConfiguration: Sendable {
    public var minPeakToRMSThreshold: Float
    public var minPeakThreshold: Float
    public var minZeroCrossingRate: Float
    public var cooldownSeconds: TimeInterval

    public init(
        minPeakToRMSThreshold: Float = 5.5,
        minPeakThreshold: Float = 0.08,
        minZeroCrossingRate: Float = 0.15,
        cooldownSeconds: TimeInterval = 0.4
    ) {
        self.minPeakToRMSThreshold = minPeakToRMSThreshold
        self.minPeakThreshold = minPeakThreshold
        self.minZeroCrossingRate = minZeroCrossingRate
        self.cooldownSeconds = cooldownSeconds
    }
}

/// Real-time transient acoustic tap detector distinguishing physical surface impacts from voice speech.
public final class TapDetector: @unchecked Sendable {
    public var config: TapDetectorConfiguration
    private var lastTapTime: Date = .distantPast

    public init(config: TapDetectorConfiguration = TapDetectorConfiguration()) {
        self.config = config
    }

    /// Evaluates an AudioFrame and FeatureVector to detect if an acoustic surface tap occurred.
    public func detectTap(in frame: AudioFrame, features: FeatureVector) -> Bool {
        let now = Date()
        guard now.timeIntervalSince(lastTapTime) >= config.cooldownSeconds else {
            return false
        }

        let maxPeak = frame.peak.max() ?? 0.0
        let maxRMS = max(frame.rms.max() ?? 0.0, 1e-6)
        let peakToRMS = maxPeak / maxRMS

        // Tap criteria: Impulsive peak, high peak-to-RMS ratio, and sharp zero-crossing rate
        let isImpulsive = peakToRMS >= config.minPeakToRMSThreshold
        let exceedsPeak = maxPeak >= config.minPeakThreshold
        let HighZCR = features.zeroCrossingRate >= config.minZeroCrossingRate

        if isImpulsive && exceedsPeak && HighZCR {
            lastTapTime = now
            return true
        }

        return false
    }
}
