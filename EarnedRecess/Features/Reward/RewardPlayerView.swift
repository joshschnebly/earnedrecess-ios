import SwiftUI
import CoreData

struct RewardPlayerView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.managedObjectContext) var context

    let onDismiss: () -> Void

    // Player state
    @State private var selectedVideo: YouTubeVideo? = nil
    @State private var isPlaying: Bool = false
    @State private var showTimerExpired: Bool = false
    @State private var showTaskGate: Bool = false

    // Session tracking
    @State private var rewardSession: RewardSession? = nil
    @State private var minutesWatchedAtStart: Int = 0

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
                        selectedVideo = video
                        startTimer()
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
                // If child earned more stars, resume
                if appState.starMinutesBalance > 0 {
                    startTimer()
                } else {
                    endSession()
                }
            })
        }
        .onAppear(perform: beginRewardSession)
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
                onPlayerReady: { isPlaying = true },
                onVideoEnded: {
                    // Video finished — go back to browser
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
        guard appState.starMinutesBalance > 0 else { endSession(); return }

        timer.start(minutes: appState.starMinutesBalance)
        timer.onExpired = {
            // Deduct all spent minutes from balance
            let spent = appState.starMinutesBalance  // was fully consumed
            StarMinutesService.shared.spend(minutes: spent, from: appState.currentChild!, context: context)
            appState.refreshBalance()
            withAnimation { showTimerExpired = true }
        }

        // Tick balance down every 60 seconds
        setupMinuteDeduction()
    }

    private func setupMinuteDeduction() {
        // We track via the timer's remaining seconds — deduct from CoreData each minute boundary
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { t in
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
