import Foundation

/// Configuration parameters for Voice Activity Detection.
public struct VADConfiguration: Sendable, Codable {
    public var minEnergyThreshold: Float
    public var snrMultiplier: Float
    public var noiseFloorAdaptationRate: Float
    public var minSpeechFrames: Int

    public init(
        minEnergyThreshold: Float = 0.008,
        snrMultiplier: Float = 2.5,
        noiseFloorAdaptationRate: Float = 0.05,
        minSpeechFrames: Int = 2
    ) {
        self.minEnergyThreshold = minEnergyThreshold
        self.snrMultiplier = snrMultiplier
        self.noiseFloorAdaptationRate = noiseFloorAdaptationRate
        self.minSpeechFrames = minSpeechFrames
    }
}

/// Lightweight adaptive Voice Activity Detector (VAD).
public final class VoiceActivityDetector: @unchecked Sendable {
    public var config: VADConfiguration
    private(set) public var currentNoiseFloor: Float
    private var consecutiveSpeechFrames: Int = 0
    private let lock = NSLock()

    public init(config: VADConfiguration = VADConfiguration(), initialNoiseFloor: Float = 0.002) {
        self.config = config
        self.currentNoiseFloor = initialNoiseFloor
    }

    /// Evaluates an AudioFrame to determine if active speech sound is present.
    public func processFrame(_ frame: AudioFrame) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        let primaryRMS = frame.rms.first ?? 0.0

        // Dynamic threshold based on adaptive noise floor
        let speechThreshold = max(config.minEnergyThreshold, currentNoiseFloor * config.snrMultiplier)

        if primaryRMS >= speechThreshold {
            consecutiveSpeechFrames += 1
            if consecutiveSpeechFrames >= config.minSpeechFrames {
                return true
            }
        } else {
            consecutiveSpeechFrames = 0
            // Adaptively update noise floor when signal is low
            currentNoiseFloor = (1.0 - config.noiseFloorAdaptationRate) * currentNoiseFloor + config.noiseFloorAdaptationRate * primaryRMS
        }

        return false
    }

    /// Resets the internal noise floor state.
    public func reset(noiseFloor: Float = 0.002) {
        lock.lock()
        defer { lock.unlock() }
        self.currentNoiseFloor = noiseFloor
        self.consecutiveSpeechFrames = 0
    }
}
