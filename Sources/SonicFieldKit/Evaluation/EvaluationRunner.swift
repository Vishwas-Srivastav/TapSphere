import Foundation

/// Benchmark sample representing ground truth vs predicted direction.
public struct EvaluationSample: Codable, Sendable {
    public let timestamp: Date
    public let actualDirection: Direction
    public let predictedDirection: Direction
    public let confidence: Float
    public let isCorrect: Bool
}

/// Benchmark metrics summary report.
public struct EvaluationReport: Codable, Sendable {
    public let totalSamples: Int
    public let correctCount: Int
    public let accuracy: Float
    public let unknownRate: Float
    public let falsePositiveRate: Float
    public let perZoneAccuracy: [Direction: Float]
    public let confusionMatrix: [Direction: [Direction: Int]]
}

/// Evaluation runner for testing classification performance against recorded benchmarks.
public final class EvaluationRunner: @unchecked Sendable {
    private var samples: [EvaluationSample] = []
    private let lock = NSLock()

    public init() {}

    public func recordSample(actual: Direction, predicted: PredictionResult) {
        lock.lock()
        defer { lock.unlock() }

        let isCorrect = (actual == predicted.direction)
        let sample = EvaluationSample(
            timestamp: Date(),
            actualDirection: actual,
            predictedDirection: predicted.direction,
            confidence: predicted.confidence,
            isCorrect: isCorrect
        )
        samples.append(sample)
    }

    public func generateReport() -> EvaluationReport {
        lock.lock()
        defer { lock.unlock() }

        let total = samples.count
        guard total > 0 else {
            return EvaluationReport(
                totalSamples: 0,
                correctCount: 0,
                accuracy: 0.0,
                unknownRate: 0.0,
                falsePositiveRate: 0.0,
                perZoneAccuracy: [:],
                confusionMatrix: [:]
            )
        }

        var correct = 0
        var unknownCount = 0
        var falsePositives = 0
        var perZoneTotal: [Direction: Int] = [:]
        var perZoneCorrect: [Direction: Int] = [:]
        var matrix: [Direction: [Direction: Int]] = [:]

        for s in samples {
            if s.isCorrect { correct += 1 }
            if s.predictedDirection == .unknown { unknownCount += 1 }
            if s.actualDirection == .unknown && s.predictedDirection != .unknown { falsePositives += 1 }

            perZoneTotal[s.actualDirection, default: 0] += 1
            if s.isCorrect {
                perZoneCorrect[s.actualDirection, default: 0] += 1
            }

            var actualRow = matrix[s.actualDirection] ?? [:]
            actualRow[s.predictedDirection, default: 0] += 1
            matrix[s.actualDirection] = actualRow
        }

        var perZoneAcc: [Direction: Float] = [:]
        for (zone, tot) in perZoneTotal {
            let cor = perZoneCorrect[zone] ?? 0
            perZoneAcc[zone] = tot > 0 ? Float(cor) / Float(tot) : 0.0
        }

        return EvaluationReport(
            totalSamples: total,
            correctCount: correct,
            accuracy: Float(correct) / Float(total),
            unknownRate: Float(unknownCount) / Float(total),
            falsePositiveRate: Float(falsePositives) / Float(max(1, perZoneTotal[.unknown] ?? 1)),
            perZoneAccuracy: perZoneAcc,
            confusionMatrix: matrix
        )
    }

    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        samples.removeAll()
    }
}
