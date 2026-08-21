import Foundation

/// Model representing a captured diagnostic session report.
public struct DiagnosticReport: Codable, Sendable {
    public let timestamp: Date
    public let deviceName: String
    public let deviceUID: String
    public let sampleRate: Double
    public let channelCount: Int
    public let formatDescription: String
    public let channelRMS: [Float]
    public let channelPeak: [Float]
    public let correlationMatrix: [String: Float]
    public let spatialVerdict: String
    public let recommendation: String
}

/// Generates JSON and Markdown reports summarizing Core Audio discovery & diagnostic test results.
public struct DiagnosticReportGenerator: Sendable {

    public static func generateReport(
        device: AudioDeviceInfo,
        rms: [Float],
        peak: [Float],
        correlationMatrix: [String: Float]
    ) -> DiagnosticReport {

        var highCorrelationCount = 0
        var pairCount = 0

        for (key, val) in correlationMatrix {
            if !key.contains("CH1 ↔ CH1") && !key.contains("CH2 ↔ CH2") && !key.contains("CH3 ↔ CH3") {
                pairCount += 1
                if val > 0.85 {
                    highCorrelationCount += 1
                }
            }
        }

        let verdict: String
        let recommendation: String

        if device.inputChannelCount == 1 {
            verdict = "Single Stream (Processed / Mono)"
            recommendation = "Use single-channel acoustic fingerprinting & spectral feature extraction."
        } else if pairCount > 0 && highCorrelationCount == pairCount {
            verdict = "Multi-Channel Processed (Beamformed Array)"
            recommendation = "Channels are highly correlated (r > 0.85). Combine spectral features with acoustic fingerprinting."
        } else if device.inputChannelCount > 1 {
            verdict = "Independent Multi-Channel Audio Stream Available"
            recommendation = "Enable GCC-PHAT TDOA spatial feature extraction along with spectral features."
        } else {
            verdict = "Unknown Audio Configuration"
            recommendation = "Run diagnostic recording while speaking from different positions around laptop."
        }

        return DiagnosticReport(
            timestamp: Date(),
            deviceName: device.name,
            deviceUID: device.uid,
            sampleRate: device.sampleRate,
            channelCount: device.inputChannelCount,
            formatDescription: device.formatDescription,
            channelRMS: rms,
            channelPeak: peak,
            correlationMatrix: correlationMatrix,
            spatialVerdict: verdict,
            recommendation: recommendation
        )
    }

    public static func exportMarkdown(report: DiagnosticReport) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium

        var md = """
        # SonicField — Mac Audio Diagnostic Report
        **Generated**: \(dateFormatter.string(from: report.timestamp))

        ## 1. Hardware Device Properties
        - **Device Name**: \(report.deviceName)
        - **Device UID**: `\(report.deviceUID)`
        - **Sample Rate**: \(Int(report.sampleRate)) Hz
        - **Input Channels**: \(report.channelCount)
        - **Stream Format**: \(report.formatDescription)

        ## 2. Audio Signal Metrics
        """

        for i in 0..<report.channelCount {
            let r = i < report.channelRMS.count ? String(format: "%.4f", report.channelRMS[i]) : "N/A"
            let p = i < report.channelPeak.count ? String(format: "%.4f", report.channelPeak[i]) : "N/A"
            md += "\n- **Channel \(i + 1)**: RMS = `\(r)`, Peak = `\(p)`"
        }

        md += "\n\n## 3. Channel Correlation Matrix\n"
        for (key, val) in report.correlationMatrix.sorted(by: { $0.key < $1.key }) {
            md += "- **\(key)**: `\(String(format: "%.4f", val))`\n"
        }

        md += """

        ## 4. Spatial Information Verdict
        **Verdict**: \(report.spatialVerdict)

        **Recommendation**: \(report.recommendation)
        """

        return md
    }

    public static func exportJSON(report: DiagnosticReport) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(report)
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}
