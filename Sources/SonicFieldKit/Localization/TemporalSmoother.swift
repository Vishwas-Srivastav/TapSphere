import Foundation

/// Temporal smoothing filter to eliminate rapid UI jitter between adjacent spatial zones.
public final class TemporalSmoother: @unchecked Sendable {
    public var alpha: Float
    public var historyWindowSize: Int
    private var rollingProbs: [Direction: Float] = [:]
    private var recentPredictions: [Direction] = []
    private let lock = NSLock()

    public init(alpha: Float = 0.35, historyWindowSize: Int = 5) {
        self.alpha = alpha
        self.historyWindowSize = historyWindowSize
    }

    /// Process a new PredictionResult and return a smoothed PredictionResult.
    public func smooth(prediction: PredictionResult) -> PredictionResult {
        lock.lock()
        defer { lock.unlock() }

        if prediction.direction == .unknown {
            recentPredictions.append(.unknown)
            if recentPredictions.count > historyWindowSize {
                recentPredictions.removeFirst()
            }
            let unknownCount = recentPredictions.filter { $0 == .unknown }.count
            if Float(unknownCount) / Float(recentPredictions.count) > 0.6 {
                return .unknown
            }
        } else {
            recentPredictions.append(prediction.direction)
            if recentPredictions.count > historyWindowSize {
                recentPredictions.removeFirst()
            }
        }

        // Exponential Moving Average over probabilities
        for (zone, prob) in prediction.zoneProbabilities {
            let current = rollingProbs[zone] ?? 0.0
            rollingProbs[zone] = (1.0 - alpha) * current + alpha * prob
        }

        let sorted = rollingProbs.sorted(by: { $0.value > $1.value })
        guard let top = sorted.first else { return prediction }

        return PredictionResult(
            direction: top.key,
            confidence: top.value,
            zoneProbabilities: rollingProbs,
            isAmbiguous: top.key == .unknown,
            rawDistance: prediction.rawDistance
        )
    }

    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        rollingProbs.removeAll()
        recentPredictions.removeAll()
    }
}
