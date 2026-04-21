import SwiftUI
import CoreData

struct RewardPlayerView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.managedObjectContext) var context

    let onDismiss: () -> Void

    // Player state
    @State private var selectedVideo: YouTubeVideo? = nil
    @State private var isPlaying: Bool = false
    @State private var playerReady: Bool = false
    @State private var showTimerExpired: Bool = false
    @State private var showTaskGate: Bool = false

    // Session tracking
    @State private var rewardSession: RewardSession? = nil
    @State private var minutesWatchedAtStart: Int = 0
    @State private var minuteTimer: Timer? = nil

    private var timer: RewardTimer { appState.rewardTimer }
    private var balance: Int { appState.starMinutesBalance }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let video = selectedVideo {
                playerView(for: video)
            } else {
                // Video browser — pick a video first
                VideoBrowserView(
                    onSelectVideo: { video in
                        playerReady = false
                        selectedVideo = video
                        beginRewardSession()
                    },
                    onStop: endSession
                )
            }

            // Timer expired overlay
            if showTimerExpired {
                TimerExpiredOverlayView(
                    onDrawMore: {
                        showTimerExpired = false
                        pauseEverything()
                        if let session = rewardSession {
                            let watched: Int
                            if let child = appState.currentChild {
                                watched = Int(child.totalStarMinutesSpent) - minutesWatchedAtStart
                            } else {
                                watched = 0
                            }
                            session.end(minutesWatched: watched,
                                        videoTitle: selectedVideo?.title,
                                        videoId: selectedVideo?.id)
                            try? context.save()
                            rewardSession = nil
                        }
                        showTaskGate = true
                    },
                    onDoneForNow: endSession
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showTimerExpired)
        .animation(.easeInOut(duration: 0.3), value: selectedVideo?.id)
        .fullScreenCover(isPresented: $showTaskGate) {
            TaskGateView(onDismiss: {
                showTaskGate = false
                appState.refreshBalance()
                if appState.starMinutesBalance > 0 {
                    startTimer()
                } else {
                    endSession()
                }
            })
        }
        .onDisappear(perform: pauseEverything)
    }

    // MARK: - Player view

    private func playerView(for video: YouTubeVideo) -> some View {
        VStack(spacing: 0) {
            // Timer bar
            RewardTimerBar(timer: timer, onStop: endSession)

            // YouTube player
            YouTubePlayerView(
                videoId: video.id,
                isPlaying: $isPlaying,
                onPlayerReady: {
                    isPlaying = true
                    if !playerReady {
                        playerReady = true
                        startTimer()
                    }
                },
                onVideoEnded: {
                    selectedVideo = nil
                }
            )
            .ignoresSafeArea(edges: .bottom)

            // Back to browser button
            Button(action: { selectedVideo = nil }) {
                Label("Choose Another Video", systemImage: "rectangle.grid.2x2")
                    .font(Theme.Fonts.childCaption(15))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Color.black)
        }
    }

    // MARK: - Timer management

    private func startTimer() {
        let isWriteToWatch = appState.parentSettings?.appModeEnum == .writeToWatch
        guard isWriteToWatch || appState.starMinutesBalance > 0 else { endSession(); return }

        timer.start(minutes: appState.starMinutesBalance)
        timer.onExpired = {
            guard let child = appState.currentChild else { endSession(); return }
            let spent = appState.starMinutesBalance
            StarMinutesService.shared.spend(minutes: spent, from: child, context: context)
            appState.refreshBalance()
            withAnimation { showTimerExpired = true }
        }

        // Tick balance down every 60 seconds
        setupMinuteDeduction()
    }

    private func setupMinuteDeduction() {
        minuteTimer?.invalidate()
        minuteTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [self] t in
            guard timer.isRunning else { t.invalidate(); return }
            guard let child = appState.currentChild else { t.invalidate(); return }
            let stillHas = StarMinutesService.shared.spendOneMinute(from: child, context: context)
            appState.refreshBalance()
            if !stillHas { t.invalidate() }
        }
    }

    private func pauseEverything() {
        timer.pause()
        isPlaying = false
        minuteTimer?.invalidate()
        minuteTimer = nil
    }

    // MARK: - Session lifecycle

    private func beginRewardSession() {
        guard let child = appState.currentChild else { return }
        rewardSession = RewardSession.create(
            minutesEarned: appState.starMinutesBalance,
            child: child,
            context: context
        )
        minutesWatchedAtStart = Int(child.totalStarMinutesSpent)
    }

    private func endSession() {
        timer.stop()
        isPlaying = false

        // Record how much was watched
        if let session = rewardSession, let child = appState.currentChild {
            let watched = Int(child.totalStarMinutesSpent) - minutesWatchedAtStart
            session.end(minutesWatched: watched,
                        videoTitle: selectedVideo?.title,
                        videoId: selectedVideo?.id)
            try? context.save()
        }

        appState.refreshBalance()
        onDismiss()
    }
}
