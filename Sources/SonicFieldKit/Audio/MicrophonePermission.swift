import Foundation
import AVFoundation

/// Manages macOS audio recording privacy permissions.
public final class MicrophonePermission: @unchecked Sendable {
    public enum Status: String, Sendable {
        case authorized
        case denied
        case restricted
        case notDetermined
    }

    public static let shared = MicrophonePermission()

    private init() {}

    /// Current microphone authorization status.
    public var status: Status {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .notDetermined
        }
    }

    /// Requests microphone access asynchronously if not determined.
    public func requestPermission() async -> Bool {
        let currentStatus = status
        if currentStatus == .authorized { return true }
        if currentStatus == .denied || currentStatus == .restricted { return false }

        return await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
    }
}
