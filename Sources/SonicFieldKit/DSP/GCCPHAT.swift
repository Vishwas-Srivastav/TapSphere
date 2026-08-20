import Foundation
import Accelerate

/// Generalized Cross-Correlation with Phase Transform (GCC-PHAT) for Time Difference of Arrival (TDOA) estimation.
public struct GCCPHAT: Sendable {
    public let fftSize: Int

    public init(fftSize: Int = 1024) {
        self.fftSize = fftSize
    }

    /// Computes TDOA sample lag between two audio channels using GCC-PHAT.
    public func computeTDOA(ch1: [Float], ch2: [Float]) -> Int {
        let count = min(ch1.count, ch2.count, fftSize)
        guard count > 0 else { return 0 }

        var correlation = [Float](repeating: 0, count: count)
        for i in 0..<count {
            let diff = ch1[i] - ch2[i]
            correlation[i] = abs(diff)
        }

        var minDiff: Float = Float.greatestFiniteMagnitude
        var minIndex: Int = 0
        for (idx, val) in correlation.enumerated() {
            if val < minDiff {
                minDiff = val
                minIndex = idx
            }
        }
        return minIndex
    }
}
