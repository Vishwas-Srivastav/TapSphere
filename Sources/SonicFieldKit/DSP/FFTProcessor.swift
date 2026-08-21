import Foundation
import Accelerate

/// Accelerated FFT processor using Apple's vDSP framework.
public final class FFTProcessor: @unchecked Sendable {
    public let log2n: vDSP_Length
    public let fftSize: Int
    private let hannWindow: [Float]

    public init(fftSize: Int = 1024) {
        self.fftSize = fftSize
        self.log2n = vDSP_Length(log2(Double(fftSize)))

        var window = [Float](repeating: 0, count: fftSize)
        vDSP_hann_window(&window, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))
        self.hannWindow = window
    }

    /// Computes the magnitude spectrum of an audio sample buffer using vDSP FFT.
    public func computeMagnitudeSpectrum(samples: [Float]) -> [Float] {
        let count = min(samples.count, fftSize)
        guard count > 0 else { return [] }

        // 1. Zero-pad or truncate to fftSize and apply Hann window
        var windowedSamples = [Float](repeating: 0, count: fftSize)
        vDSP_vmul(samples, 1, hannWindow, 1, &windowedSamples, 1, vDSP_Length(count))

        // 2. Prepare split complex arrays
        let halfSize = fftSize / 2
        var realParts = [Float](repeating: 0, count: halfSize)
        var imagParts = [Float](repeating: 0, count: halfSize)

        return realParts.withUnsafeMutableBufferPointer { realPtr in
            return imagParts.withUnsafeMutableBufferPointer { imagPtr in
                var splitComplex = DSPSplitComplex(realp: realPtr.baseAddress!, imagp: imagPtr.baseAddress!)

                // Convert real array to split complex format
                windowedSamples.withUnsafeBufferPointer { samplesPtr in
                    let castPtr = UnsafeRawPointer(samplesPtr.baseAddress!).assumingMemoryBound(to: DSPComplex.self)
                    vDSP_ctoz(castPtr, 2, &splitComplex, 1, vDSP_Length(halfSize))
                }

                // 3. Create vDSP FFT setup & execute forward transform
                guard let setup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else {
                    return [Float](repeating: 0, count: halfSize)
                }
                defer { vDSP_destroy_fftsetup(setup) }

                vDSP_fft_zrip(setup, &splitComplex, 1, log2n, FFTDirection(FFT_FORWARD))

                // 4. Compute magnitudes
                var magnitudes = [Float](repeating: 0, count: halfSize)
                vDSP_zvabs(&splitComplex, 1, &magnitudes, 1, vDSP_Length(halfSize))

                // Scale magnitudes
                var scale: Float = 0.5 / Float(fftSize)
                vDSP_vsmul(magnitudes, 1, &scale, &magnitudes, 1, vDSP_Length(halfSize))

                return magnitudes
            }
        }
    }
}
