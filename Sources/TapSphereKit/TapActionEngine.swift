import Foundation
import AppKit
import Combine

/// TapSphere engine coordinator handling real-time audio capture, tap detection, audio feedback, and action dispatch.
@MainActor
public final class TapActionEngine: ObservableObject {
    @Published public var isEnabled: Bool = true
    @Published public var playSoundFeedback: Bool = true
    @Published public var sensitivityThreshold: Float = 5.5
    @Published public var activeQuadrant: LaptopQuadrant = .unknown
    @Published public var lastTriggeredRecord: TapEventRecord?

    public let appState: AppState
    private var cancellables = Set<AnyCancellable>()

    public init() {
        self.appState = AppState()
        setupListeners()
    }

    private func setupListeners() {
        appState.$lastTapEvent
            .compactMap { $0 }
            .sink { [weak self] record in
                guard let self = self, self.isEnabled else { return }
                self.handleTapRecord(record)
            }
            .store(in: &cancellables)

        appState.$currentQuadrant
            .sink { [weak self] quad in
                self?.activeQuadrant = quad
            }
            .store(in: &cancellables)
    }

    public func start() {
        appState.startCapture()
    }

    public func stop() {
        appState.stopCapture()
    }

    public func toggleEnabled() {
        isEnabled.toggle()
        if isEnabled {
            start()
        } else {
            stop()
        }
    }

    private func handleTapRecord(_ record: TapEventRecord) {
        self.lastTriggeredRecord = record

        if playSoundFeedback {
            if let sound = NSSound(named: "Tink") ?? NSSound(named: "Pop") {
                sound.play()
            }
        }
    }
}
