import Foundation
import AppKit
import Combine

/// TapSphere engine coordinator handling real-time audio capture, tap detection, audio feedback, and action dispatch.
@MainActor
public final class TapActionEngine: ObservableObject {
    @Published public var isEnabled: Bool = true
    @Published public var playSoundFeedback: Bool = true
    @Published public var sensitivityThreshold: Float = 4.0
    @Published public var activeQuadrant: LaptopQuadrant = .unknown
    @Published public var lastTriggeredRecord: TapEventRecord?

    public let appState: AppState
    private var cancellables = Set<AnyCancellable>()
    private var resetQuadrantTask: Task<Void, Never>?

    public init() {
        self.appState = AppState()
        setupListeners()
        start()
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
                guard let self = self else { return }
                self.activeQuadrant = quad
                self.resetQuadrantTask?.cancel()
                if quad != .unknown {
                    self.resetQuadrantTask = Task {
                        try? await Task.sleep(nanoseconds: 1_500_000_000)
                        if !Task.isCancelled {
                            self.activeQuadrant = .unknown
                        }
                    }
                }
            }
            .store(in: &cancellables)

        $sensitivityThreshold
            .sink { [weak self] val in
                self?.appState.tapDetector.config.minPeakToRMSThreshold = val
            }
            .store(in: &cancellables)
    }

    public func start() {
        isEnabled = true
        appState.startCapture()
    }

    public func stop() {
        isEnabled = false
        appState.stopCapture()
    }

    public func toggleEnabled() {
        if isEnabled {
            stop()
        } else {
            start()
        }
    }

    private func handleTapRecord(_ record: TapEventRecord) {
        self.lastTriggeredRecord = record

        if playSoundFeedback {
            Task.detached(priority: .high) {
                if let sound = NSSound(named: "Tink") ?? NSSound(named: "Pop") {
                    sound.play()
                }
            }
        }
    }
}
