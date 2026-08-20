import Foundation

/// Configuration parameters for adaptive onset tap detection.
public struct TapDetectorConfiguration: Sendable {
    public var minPeakSpikeRatio: Float
    public var minRMSSpikeRatio: Float
    public var minPeakToRMSThreshold: Float
    public var cooldownSeconds: TimeInterval

    public init(
        minPeakSpikeRatio: Float = 3.5,
        minRMSSpikeRatio: Float = 3.0,
        minPeakToRMSThreshold: Float = 5.0,
        cooldownSeconds: TimeInterval = 0.8
    ) {
        self.minPeakSpikeRatio = minPeakSpikeRatio
        self.minRMSSpikeRatio = minRMSSpikeRatio
        self.minPeakToRMSThreshold = minPeakToRMSThreshold
        self.cooldownSeconds = cooldownSeconds
    }
}

/// Adaptive onset acoustic tap detector distinguishing physical surface impacts from voice & background noise.
public final class TapDetector: @unchecked Sendable {
    public var config: TapDetectorConfiguration
    private var lastTapTime: Date = .distantPast

    // Adaptive Noise Floor Tracking
    private var adaptiveRMSFloor: Float = 0.005
    private var adaptivePeakFloor: Float = 0.020
    private let adaptationRate: Float = 0.05
    private let lock = NSLock()

    public init(config: TapDetectorConfiguration = TapDetectorConfiguration()) {
        self.config = config
    }

    /// Evaluates an AudioFrame to detect if an acoustic surface tap onset occurred.
    public func detectTap(in frame: AudioFrame, features: FeatureVector) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        let now = Date()
        let framePeak = frame.peak.max() ?? 0.0
        let frameRMS = max(frame.rms.max() ?? 0.0, 1e-6)

        // 1. Evaluate ONSET SPIKE ratio relative to adaptive baseline noise floor
        let peakSpikeRatio = framePeak / max(adaptivePeakFloor, 1e-4)
        let rmsSpikeRatio = frameRMS / max(adaptiveRMSFloor, 1e-4)
        let peakToRMS = framePeak / frameRMS

        // Onset Tap Criteria:
        let isOnsetSpike = peakSpikeRatio >= config.minPeakSpikeRatio && rmsSpikeRatio >= config.minRMSSpikeRatio
        let isImpulsive = peakToRMS >= config.minPeakToRMSThreshold
        let cooldownPassed = now.timeIntervalSince(lastTapTime) >= config.cooldownSeconds

        if isOnsetSpike && isImpulsive && cooldownPassed {
            lastTapTime = now
            return true
        }

        // Adaptively update noise floor during quiet/non-tap periods
        if peakSpikeRatio < 2.0 {
            adaptiveRMSFloor = (1.0 - adaptationRate) * adaptiveRMSFloor + adaptationRate * frameRMS
            adaptivePeakFloor = (1.0 - adaptationRate) * adaptivePeakFloor + adaptationRate * framePeak
        }

        return false
    }

    /// Resets the adaptive noise floor.
    public func resetNoiseFloor(rms: Float = 0.005, peak: Float = 0.020) {
        lock.lock()
        defer { lock.unlock() }
        self.adaptiveRMSFloor = rms
        self.adaptivePeakFloor = peak
        self.lastTapTime = .distantPast
    }
}
