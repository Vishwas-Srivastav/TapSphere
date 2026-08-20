import Foundation
import AVFoundation
import os

/// Protocol defining real-time audio capture capabilities.
public protocol AudioCaptureServiceProtocol: Sendable {
    func start() async throws
    func stop()
    var isRecording: Bool { get }
    var audioStream: AsyncStream<AudioFrame> { get }
}

/// Real-time audio capture service wrapping AVAudioEngine and input taps.
public final class AudioCaptureService: AudioCaptureServiceProtocol, @unchecked Sendable {
    private let audioEngine = AVAudioEngine()
    private var streamContinuation: AsyncStream<AudioFrame>.Continuation?
    private let recordingState = OSAllocatedUnfairLock(initialState: false)

    public var isRecording: Bool {
        recordingState.withLock { $0 }
    }

    public let audioStream: AsyncStream<AudioFrame>

    public init(bufferSize: UInt32 = 1024) {
        var continuation: AsyncStream<AudioFrame>.Continuation?
        self.audioStream = AsyncStream<AudioFrame> { cont in
            continuation = cont
        }
        self.streamContinuation = continuation
    }

    public func start() async throws {
        let granted = await MicrophonePermission.shared.requestPermission()
        guard granted else {
            throw NSError(
                domain: "SonicField.AudioCaptureService",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Microphone permission denied."]
            )
        }

        let alreadyRecording = recordingState.withLock { recording in
            if recording { return true }
            recording = true
            return false
        }

        if alreadyRecording { return }

        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 2048, format: inputFormat) { [weak self] buffer, time in
            guard let self = self else { return }
            self.processTapBuffer(buffer: buffer, timestamp: time)
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

    public func stop() {
        let wasRecording = recordingState.withLock { recording in
            let prev = recording
            recording = false
            return prev
        }

        guard wasRecording else { return }

        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
    }

    private func processTapBuffer(buffer: AVAudioPCMBuffer, timestamp: AVAudioTime) {
        guard let floatChannelData = buffer.floatChannelData else { return }
        let channelCount = Int(buffer.format.channelCount)
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0, channelCount > 0 else { return }

        var channelSamples: [[Float]] = []
        for ch in 0..<channelCount {
            let channelPtr = floatChannelData[ch]
            let sampleBuffer = Array(UnsafeBufferPointer(start: channelPtr, count: frameLength))
            channelSamples.append(sampleBuffer)
        }

        let audioFrame = AudioFrame(
            timestamp: Date(),
            sampleRate: buffer.format.sampleRate,
            channelCount: channelCount,
            frameCount: frameLength,
            samples: channelSamples
        )

        streamContinuation?.yield(audioFrame)
    }

    deinit {
        stop()
        streamContinuation?.finish()
    }
}
