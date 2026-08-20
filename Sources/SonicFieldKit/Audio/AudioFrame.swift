import Foundation

/// Represents a multi-channel buffer of PCM audio samples captured in real time.
public struct AudioFrame: Sendable, Identifiable {
    public let id: UUID
    public let timestamp: Date
    public let sampleRate: Double
    public let channelCount: Int
    public let frameCount: Int
    /// Samples indexed by channel: `samples[channelIndex][sampleIndex]`
    public let samples: [[Float]]
    /// Precomputed Root Mean Square (RMS) energy per channel
    public let rms: [Float]
    /// Precomputed peak amplitude per channel
    public let peak: [Float]

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        sampleRate: Double,
        channelCount: Int,
        frameCount: Int,
        samples: [[Float]]
    ) {
        self.id = id
        self.timestamp = timestamp
        self.sampleRate = sampleRate
        self.channelCount = channelCount
        self.frameCount = frameCount
        self.samples = samples

        // Compute RMS and peak for each channel
        var computedRMS = [Float](repeating: 0, count: channelCount)
        var computedPeak = [Float](repeating: 0, count: channelCount)

        for ch in 0..<channelCount {
            if ch < samples.count {
                let channelSamples = samples[ch]
                if !channelSamples.isEmpty {
                    var sumSquares: Float = 0
                    var maxAmp: Float = 0
                    for sample in channelSamples {
                        let absVal = abs(sample)
                        if absVal > maxAmp { maxAmp = absVal }
                        sumSquares += sample * sample
                    }
                    computedRMS[ch] = sqrt(sumSquares / Float(channelSamples.count))
                    computedPeak[ch] = maxAmp
                }
            }
        }

        self.rms = computedRMS
        self.peak = computedPeak
    }
}
