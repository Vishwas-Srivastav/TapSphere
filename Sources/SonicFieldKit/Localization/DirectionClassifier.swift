import Foundation

/// Prediction output containing the detected direction, confidence score, and zone probabilities.
public struct PredictionResult: Sendable, Codable {
    public let direction: Direction
    public let confidence: Float
    public let zoneProbabilities: [Direction: Float]
    public let isAmbiguous: Bool
    public let rawDistance: Float

    public init(
        direction: Direction,
        confidence: Float,
        zoneProbabilities: [Direction: Float],
        isAmbiguous: Bool,
        rawDistance: Float
    ) {
        self.direction = direction
        self.confidence = confidence
        self.zoneProbabilities = zoneProbabilities
        self.isAmbiguous = isAmbiguous
        self.rawDistance = rawDistance
    }

    public static var unknown: PredictionResult {
        PredictionResult(
            direction: .unknown,
            confidence: 0.0,
            zoneProbabilities: [:],
            isAmbiguous: true,
            rawDistance: 999.0
        )
    }
}

/// Interpretable distance-based classifier for spatial sound localization.
public final class DirectionClassifier: @unchecked Sendable {
    public var minConfidenceThreshold: Float
    public var marginThreshold: Float
    private var profileCentroids: [Direction: [Float]] = [:]
    private var negativeCentroid: [Float]?
    private let lock = NSLock()

    public init(minConfidenceThreshold: Float = 0.50, marginThreshold: Float = 0.15) {
        self.minConfidenceThreshold = minConfidenceThreshold
        self.marginThreshold = marginThreshold
    }

    /// Trains the classifier with a `CalibrationProfile`.
    public func loadProfile(_ profile: CalibrationProfile) {
        lock.lock()
        defer { lock.unlock() }

        var centroids: [Direction: [Float]] = [:]

        for (zone, samples) in profile.zoneSamples {
            guard !samples.isEmpty else { continue }
            let featureLength = samples[0].rawFeatures.count
            var sumVec = [Float](repeating: 0, count: featureLength)

            for sample in samples {
                let raw = sample.rawFeatures
                for i in 0..<min(featureLength, raw.count) {
                    sumVec[i] += raw[i]
                }
            }

            let count = Float(samples.count)
            let meanVec = sumVec.map { $0 / count }
            centroids[zone] = meanVec
        }

        self.profileCentroids = centroids

        if !profile.negativeSamples.isEmpty {
            let featureLength = profile.negativeSamples[0].rawFeatures.count
            var sumVec = [Float](repeating: 0, count: featureLength)
            for sample in profile.negativeSamples {
                let raw = sample.rawFeatures
                for i in 0..<min(featureLength, raw.count) {
                    sumVec[i] += raw[i]
                }
            }
            let count = Float(profile.negativeSamples.count)
            self.negativeCentroid = sumVec.map { $0 / count }
        } else {
            self.negativeCentroid = nil
        }
    }

    /// Classifies an incoming `FeatureVector` into a `PredictionResult`.
    public func classify(featureVector: FeatureVector) -> PredictionResult {
        lock.lock()
        let centroids = self.profileCentroids
        let negCentroid = self.negativeCentroid
        lock.unlock()

        guard !centroids.isEmpty else { return .unknown }

        let inputVec = featureVector.rawFeatures

        // Check negative noise rejection
        if let neg = negCentroid {
            let negDist = euclideanDistance(inputVec, neg)
            let minZoneDist = centroids.values.map { euclideanDistance(inputVec, $0) }.min() ?? 999.0
            if negDist < minZoneDist {
                return PredictionResult(
                    direction: .unknown,
                    confidence: 0.1,
                    zoneProbabilities: [:],
                    isAmbiguous: true,
                    rawDistance: negDist
                )
            }
        }

        // Calculate inverse distance scores for each zone
        var distances: [Direction: Float] = [:]
        for (zone, centroid) in centroids {
            let dist = euclideanDistance(inputVec, centroid)
            distances[zone] = dist
        }

        // Softmax conversion
        let temperature: Float = 0.5
        var expScores: [Direction: Float] = [:]
        var sumExp: Float = 0.0

        for (zone, dist) in distances {
            let expVal = exp(-dist / temperature)
            expScores[zone] = expVal
            sumExp += expVal
        }

        guard sumExp > 1e-6 else { return .unknown }

        var probs: [Direction: Float] = [:]
        for (zone, expVal) in expScores {
            probs[zone] = expVal / sumExp
        }

        // Sort predictions by probability
        let sorted = probs.sorted(by: { $0.value > $1.value })
        guard let top = sorted.first else { return .unknown }

        let topZone = top.key
        let topProb = top.value
        let secondProb = sorted.count > 1 ? sorted[1].value : 0.0
        let margin = topProb - secondProb

        // UNKNOWN Rejection Checks
        let isAmbiguous = (topProb < minConfidenceThreshold) || (margin < marginThreshold)
        let finalDirection: Direction = isAmbiguous ? .unknown : topZone

        return PredictionResult(
            direction: finalDirection,
            confidence: topProb,
            zoneProbabilities: probs,
            isAmbiguous: isAmbiguous,
            rawDistance: distances[topZone] ?? 0.0
        )
    }

    private func euclideanDistance(_ a: [Float], _ b: [Float]) -> Float {
        let count = min(a.count, b.count)
        guard count > 0 else { return 999.0 }
        var sumSq: Float = 0.0
        for i in 0..<count {
            let diff = a[i] - b[i]
            sumSq += diff * diff
        }
        return sqrt(sumSq)
    }
}
