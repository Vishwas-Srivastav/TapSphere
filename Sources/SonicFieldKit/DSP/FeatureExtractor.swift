import Foundation
import Accelerate

/// Vector of extracted acoustic features used for spatial sound localization classification.
public struct FeatureVector: Codable, Sendable, Equatable {
    public let timestamp: Date
    public let rms: Float
    public let peak: Float
    public let zeroCrossingRate: Float
    public let spectralCentroid: Float
    public let spectralRolloff: Float
    public let bandEnergies: [Float]
    public let mfccs: [Float]
    public let channelEnergyRatios: [Float]
    public let pairwiseCorrelations: [Float]

    public init(
        timestamp: Date = Date(),
        rms: Float,
        peak: Float,
        zeroCrossingRate: Float,
        spectralCentroid: Float,
        spectralRolloff: Float,
        bandEnergies: [Float],
        mfccs: [Float],
        channelEnergyRatios: [Float] = [],
        pairwiseCorrelations: [Float] = []
    ) {
        self.timestamp = timestamp
        self.rms = rms
        self.peak = peak
        self.zeroCrossingRate = zeroCrossingRate
        self.spectralCentroid = spectralCentroid
        self.spectralRolloff = spectralRolloff
        self.bandEnergies = bandEnergies
        self.mfccs = mfccs
        self.channelEnergyRatios = channelEnergyRatios
        self.pairwiseCorrelations = pairwiseCorrelations
    }

    /// Flattened numerical array for classifier distance & model input.
    public var rawFeatures: [Float] {
        var arr: [Float] = [
            rms,
            peak,
            zeroCrossingRate,
            spectralCentroid / 10000.0, // normalized
            spectralRolloff / 10000.0   // normalized
        ]
        arr.append(contentsOf: bandEnergies)
        arr.append(contentsOf: mfccs)
        arr.append(contentsOf: channelEnergyRatios)
        arr.append(contentsOf: pairwiseCorrelations)
        return arr
    }
}

/// Feature extraction engine for audio frames.
public final class FeatureExtractor: @unchecked Sendable {
    private let fftProcessor: FFTProcessor

    public init(fftSize: Int = 1024) {
        self.fftProcessor = FFTProcessor(fftSize: fftSize)
    }

    /// Extracts a comprehensive `FeatureVector` from an `AudioFrame`.
    public func extractFeatures(from frame: AudioFrame) -> FeatureVector {
        let primaryChannel = frame.samples.first ?? []
        let sampleRate = Float(frame.sampleRate)

        // 1. Time-domain metrics
        let rmsVal = frame.rms.first ?? 0.0
        let peakVal = frame.peak.first ?? 0.0
        let zcr = computeZeroCrossingRate(samples: primaryChannel)

        // 2. Frequency-domain metrics via FFT
        let magSpectrum = fftProcessor.computeMagnitudeSpectrum(samples: primaryChannel)
        let centroid = computeSpectralCentroid(spectrum: magSpectrum, sampleRate: sampleRate)
        let rolloff = computeSpectralRolloff(spectrum: magSpectrum, sampleRate: sampleRate, threshold: 0.85)
        let subBands = computeSubBandEnergies(spectrum: magSpectrum, numBands: 8)
        let melEnergies = computeLogMelEnergies(spectrum: magSpectrum, sampleRate: sampleRate, numFilters: 12)

        // 3. Multi-channel spatial features
        var energyRatios: [Float] = []
        var correlations: [Float] = []

        if frame.channelCount > 1 {
            let totalRMS = frame.rms.reduce(0, +) + 1e-6
            for rms in frame.rms {
                energyRatios.append(rms / totalRMS)
            }
            for i in 0..<frame.channelCount {
                for j in (i+1)..<frame.channelCount {
                    let r = ChannelCorrelation.computePearson(ch1: frame.samples[i], ch2: frame.samples[j])
                    correlations.append(r)
                }
            }
        }

        return FeatureVector(
            timestamp: frame.timestamp,
            rms: rmsVal,
            peak: peakVal,
            zeroCrossingRate: zcr,
            spectralCentroid: centroid,
            spectralRolloff: rolloff,
            bandEnergies: subBands,
            mfccs: melEnergies,
            channelEnergyRatios: energyRatios,
            pairwiseCorrelations: correlations
        )
    }

    // MARK: - Feature Calculations

    public func computeZeroCrossingRate(samples: [Float]) -> Float {
        guard samples.count > 1 else { return 0.0 }
        var crossings = 0
        for i in 1..<samples.count {
            if (samples[i] >= 0 && samples[i - 1] < 0) || (samples[i] < 0 && samples[i - 1] >= 0) {
                crossings += 1
            }
        }
        return Float(crossings) / Float(samples.count - 1)
    }

    public func computeSpectralCentroid(spectrum: [Float], sampleRate: Float) -> Float {
        guard !spectrum.isEmpty else { return 0.0 }
        let binWidth = (sampleRate / 2.0) / Float(spectrum.count)
        var sumWeightedMag: Float = 0
        var sumMag: Float = 0

        for (i, mag) in spectrum.enumerated() {
            let freq = Float(i) * binWidth
            sumWeightedMag += freq * mag
            sumMag += mag
        }
        return sumMag > 1e-6 ? (sumWeightedMag / sumMag) : 0.0
    }

    public func computeSpectralRolloff(spectrum: [Float], sampleRate: Float, threshold: Float = 0.85) -> Float {
        guard !spectrum.isEmpty else { return 0.0 }
        let totalEnergy = spectrum.reduce(0, +)
        let energyThreshold = totalEnergy * threshold
        let binWidth = (sampleRate / 2.0) / Float(spectrum.count)

        var cumulativeEnergy: Float = 0
        for (i, mag) in spectrum.enumerated() {
            cumulativeEnergy += mag
            if cumulativeEnergy >= energyThreshold {
                return Float(i) * binWidth
            }
        }
        return sampleRate / 2.0
    }

    public func computeSubBandEnergies(spectrum: [Float], numBands: Int = 8) -> [Float] {
        guard !spectrum.isEmpty, numBands > 0 else { return [Float](repeating: 0, count: numBands) }
        let chunkSize = max(1, spectrum.count / numBands)
        var bands = [Float](repeating: 0, count: numBands)

        for i in 0..<numBands {
            let start = i * chunkSize
            let end = (i == numBands - 1) ? spectrum.count : min(spectrum.count, start + chunkSize)
            if start < end {
                let slice = spectrum[start..<end]
                bands[i] = slice.reduce(0, +) / Float(end - start)
            }
        }
        return bands
    }

    public func computeLogMelEnergies(spectrum: [Float], sampleRate: Float, numFilters: Int = 12) -> [Float] {
        guard !spectrum.isEmpty else { return [Float](repeating: 0, count: numFilters) }
        let chunkSize = max(1, spectrum.count / numFilters)
        var mels = [Float](repeating: 0, count: numFilters)

        for i in 0..<numFilters {
            let start = i * chunkSize
            let end = min(spectrum.count, start + chunkSize)
            if start < end {
                let energy = spectrum[start..<end].reduce(0, +)
                mels[i] = log(max(1e-6, energy))
            }
        }
        return mels
    }
}
