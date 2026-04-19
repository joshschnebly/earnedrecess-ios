import Foundation
import UIKit
import Combine

class RewardTimer: ObservableObject {
    @Published var remainingSeconds: Int = 0
    @Published var isRunning: Bool = false
    @Published var isExpired: Bool = false

    private var timer: Timer?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var backgroundEnteredAt: Date? = nil
    private var totalSecondsAtStart: Int = 0

    var onExpired: (() -> Void)?

    // MARK: - Public API

    func start(minutes: Int) {
        guard minutes > 0 else { return }
        totalSecondsAtStart = minutes * 60
        remainingSeconds = totalSecondsAtStart
        isExpired = false
        resume()
        observeBackground()
    }

    func pause() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        endBackgroundTask()
    }

    func resume() {
        guard remainingSeconds > 0 else { return }
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer!, forMode: .common)
        beginBackgroundTask()
    }

    func stop() {
        pause()
        remainingSeconds = 0
        isExpired = false
        totalSecondsAtStart = 0
    }

    func addMinutes(_ minutes: Int) {
        totalSecondsAtStart += minutes * 60
        remainingSeconds += minutes * 60
        isExpired = false
        if !isRunning { resume() }
    }

    // MARK: - Computed

    var remainingMinutes: Int { remainingSeconds / 60 }
    var displayString: String { remainingSeconds.asTimerString }

    var progressFraction: Double {
        guard totalSecondsAtStart > 0 else { return 0 }
        return Double(remainingSeconds) / Double(totalSecondsAtStart)
    }

    // MARK: - Private

    private func tick() {
        guard remainingSeconds > 0 else { expire(); return }
        remainingSeconds -= 1
        if remainingSeconds == 0 { expire() }
    }

    private func expire() {
        pause()
        isExpired = true
        onExpired?()
    }

    // MARK: - Background

    private func observeBackground() {
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBackground),
            name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidForeground),
            name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    @objc private func appDidBackground() {
        backgroundEnteredAt = Date()
        beginBackgroundTask()
    }

    @objc private func appDidForeground() {
        if let enteredAt = backgroundEnteredAt {
            let elapsed = Int(Date().timeIntervalSince(enteredAt))
            remainingSeconds = max(0, remainingSeconds - elapsed)
            backgroundEnteredAt = nil
            if remainingSeconds == 0 { expire() }
        }
    }

    private func beginBackgroundTask() {
        guard backgroundTask == .invalid else { return }
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }

    private func endBackgroundTask() {
        guard backgroundTask != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        pause()
    }
}
