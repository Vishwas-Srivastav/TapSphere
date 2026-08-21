import Foundation
import Accelerate

/// Utility for computing Pearson cross-correlation between audio channels.
public struct ChannelCorrelation: Sendable {
    
    /// Computes Pearson correlation coefficient r between two channel sample arrays [-1.0, 1.0].
    public static func computePearson(ch1: [Float], ch2: [Float]) -> Float {
        let count = min(ch1.count, ch2.count)
        guard count > 0 else { return 0.0 }

        var mean1: Float = 0
        var mean2: Float = 0
        vDSP_meanv(ch1, 1, &mean1, vDSP_Length(count))
        vDSP_meanv(ch2, 1, &mean2, vDSP_Length(count))

        var sub1 = [Float](repeating: 0, count: count)
        var sub2 = [Float](repeating: 0, count: count)
        var negMean1 = -mean1
        var negMean2 = -mean2

        vDSP_vsadd(ch1, 1, &negMean1, &sub1, 1, vDSP_Length(count))
        vDSP_vsadd(ch2, 1, &negMean2, &sub2, 1, vDSP_Length(count))

        var dotProduct: Float = 0
        vDSP_dotpr(sub1, 1, sub2, 1, &dotProduct, vDSP_Length(count))

        var sumSq1: Float = 0
        var sumSq2: Float = 0
        vDSP_svesq(sub1, 1, &sumSq1, vDSP_Length(count))
        vDSP_svesq(sub2, 1, &sumSq2, vDSP_Length(count))

        let denominator = sqrt(sumSq1 * sumSq2)
        guard denominator > 1e-7 else { return 1.0 }

        let r = dotProduct / denominator
        return max(-1.0, min(1.0, r))
    }

    /// Computes a pairwise correlation matrix for all channel combinations.
    /// Returns a dictionary mapping `"CHi-CHj"` string keys to correlation values.
    public static func computeMatrix(samples: [[Float]]) -> [String: Float] {
        let channelCount = samples.count
        var matrix: [String: Float] = [:]

        for i in 0..<channelCount {
            for j in i..<channelCount {
                let key = "CH\(i + 1) ↔ CH\(j + 1)"
                if i == j {
                    matrix[key] = 1.0
                } else {
                    let r = computePearson(ch1: samples[i], ch2: samples[j])
                    matrix[key] = r
                }
            }
        }
        return matrix
    }
}
