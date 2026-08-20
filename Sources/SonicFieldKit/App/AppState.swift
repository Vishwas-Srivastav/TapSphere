import Foundation
import SwiftUI
import Combine

/// Core application state coordinator for SonicField.
@MainActor
public final class AppState: ObservableObject {
    @Published public var selectedTab: Int = 0 // 0: Diagnostics, 1: Spatial UI, 2: Calibration, 3: Actions, 4: Benchmark

    // Hardware & Permission state
    @Published public var permissionStatus: MicrophonePermission.Status = .notDetermined
    @Published public var discoveredDevices: [AudioDeviceInfo] = []
    @Published public var selectedDevice: AudioDeviceInfo?

    // Audio stream & metrics state
    @Published public var isCapturing: Bool = false
    @Published public var currentRMS: [Float] = []
    @Published public var currentPeak: [Float] = []
    @Published public var correlationMatrix: [String: Float] = [:]
    @Published public var lastAudioFrame: AudioFrame?

    // Localization state
    @Published public var isSpeechDetected: Bool = false
    @Published public var currentPrediction: PredictionResult = .unknown
    @Published public var currentQuadrant: LaptopQuadrant = .unknown
    @Published public var lastTapEvent: TapEventRecord?
    @Published public var activeProfile: CalibrationProfile?
    @Published public var availableProfiles: [CalibrationProfile] = []

    // Services
    public let captureService: AudioCaptureService
    public let vad: VoiceActivityDetector
    public let tapDetector: TapDetector
    public let featureExtractor: FeatureExtractor
    public let classifier: DirectionClassifier
    public let smoother: TemporalSmoother
    public let actionManager: ActionManager

    private var captureTask: Task<Void, Never>?

    public init() {
        self.captureService = AudioCaptureService()
        self.vad = VoiceActivityDetector()
        self.tapDetector = TapDetector()
        self.featureExtractor = FeatureExtractor()
        self.classifier = DirectionClassifier()
        self.smoother = TemporalSmoother()
        self.actionManager = ActionManager.shared

        refreshHardwareInfo()
    }

    public func refreshHardwareInfo() {
        self.permissionStatus = MicrophonePermission.shared.status
        let devices = AudioDeviceInspector.shared.discoverInputDevices()
        self.discoveredDevices = devices
        self.selectedDevice = AudioDeviceInspector.shared.getBuiltInOrDefaultMicrophone()
        self.availableProfiles = CalibrationManager.shared.loadAllProfiles()
        if let firstProfile = availableProfiles.first {
            self.activeProfile = firstProfile
            self.classifier.loadProfile(firstProfile)
        }
    }

    public func startCapture() {
        guard !isCapturing else { return }
        isCapturing = true

        captureTask = Task {
            do {
                try await captureService.start()
                for await frame in captureService.audioStream {
                    guard !Task.isCancelled else { break }
                    await self.processIncomingFrame(frame)
                }
            } catch {
                print("Capture error: \(error.localizedDescription)")
                self.isCapturing = false
            }
        }
    }

    public func stopCapture() {
        captureService.stop()
        captureTask?.cancel()
        captureTask = nil
        isCapturing = false
    }

    private func processIncomingFrame(_ frame: AudioFrame) async {
        self.lastAudioFrame = frame
        self.currentRMS = frame.rms
        self.currentPeak = frame.peak

        if frame.channelCount > 1 {
            self.correlationMatrix = ChannelCorrelation.computeMatrix(samples: frame.samples)
        }

        let features = featureExtractor.extractFeatures(from: frame)

        // 1. Physical Desk Tap Detection & Action Triggering
        let isTap = tapDetector.detectTap(in: frame, features: features)
        if isTap {
            let rawPred = classifier.classify(featureVector: features)
            let quad = rawPred.direction.laptopQuadrant
            self.currentQuadrant = quad
            if quad != .unknown {
                if let event = actionManager.dispatchTap(quadrant: quad) {
                    self.lastTapEvent = event
                }
            }
        }

        // 2. Continuous Voice Activity & Localization Processing
        let speechPresent = vad.processFrame(frame)
        self.isSpeechDetected = speechPresent

        if speechPresent {
            let rawPred = classifier.classify(featureVector: features)
            let smoothedPred = smoother.smooth(prediction: rawPred)
            self.currentPrediction = smoothedPred
            self.currentQuadrant = smoothedPred.direction.laptopQuadrant
        }
    }
}
