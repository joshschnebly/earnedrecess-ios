import SwiftUI

struct ChildHomeView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.managedObjectContext) var context

    @State private var showPINEntry: Bool = false
    @State private var showParentModule: Bool = false
    @State private var navigateToTask: Bool = false
    @State private var navigateToReward: Bool = false

    private var hasStars: Bool { appState.starMinutesBalance > 0 }
    private var childName: String { appState.currentChild?.name ?? "Friend" }

    var body: some View {
        ZStack {
            Color.erBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                StarWalletTopBar(balance: appState.starMinutesBalance)

                Spacer()

                VStack(spacing: 20) {
                    MascotView(hasStars: hasStars)

                    Text(hasStars
                         ? "You have \(appState.starMinutesBalance.asStarMinutesLabel)!"
                         : "Draw letters to earn Star Minutes!")
                        .font(Theme.Fonts.childBody(28))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.Sizing.padding)
                }

                Spacer()

                HStack(spacing: 20) {
                    ChildActionButton(
                        icon: "🎨",
                        label: "Draw\nLetters",
                        color: .erBlue,
                        isEnabled: true,
                        action: { navigateToTask = true }
                    )
                    ChildActionButton(
                        icon: "📺",
                        label: "Watch\nYouTube",
                        color: .erGreen,
                        isEnabled: hasStars,
                        action: { navigateToReward = true }
                    )
                }
                .padding(.horizontal, Theme.Sizing.padding)
                .padding(.bottom, 48)
            }

            // Hidden triple-tap trigger — top-right corner
            VStack {
                HStack {
                    Spacer()
                    Color.clear
                        .frame(width: 80, height: 80)
                        .contentShape(Rectangle())
                        .onTapGesture(count: 3) { showPINEntry = true }
                }
                Spacer()
            }
        }
        .fullScreenCover(isPresented: $showPINEntry) {
            PINEntryView(
                onSuccess: {
                    showPINEntry = false
                    showParentModule = true
                },
                onCancel: { showPINEntry = false }
            )
        }
        .fullScreenCover(isPresented: $showParentModule) {
            ParentTabView(onExitToChild: { showParentModule = false })
        }
        .fullScreenCover(isPresented: $navigateToTask) {
            TaskGateView(onDismiss: {
                navigateToTask = false
                appState.refreshBalance()
            })
        }
        .fullScreenCover(isPresented: $navigateToReward) {
            RewardPlayerView(onDismiss: {
                navigateToReward = false
                appState.refreshBalance()
            })
        }
        .onAppear { appState.refreshBalance() }
    }
}

// MARK: - Action Button

struct ChildActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Text(icon).font(.system(size: 56))
                Text(label)
                    .font(Theme.Fonts.childBody(24))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .background(isEnabled ? color : Color.gray.opacity(0.35))
            .cornerRadius(Theme.Sizing.primaryButtonCornerRadius)
            .buttonShadow()
            .scaleEffect(isEnabled ? 1.0 : 0.97)
        }
        .disabled(!isEnabled)
        .animation(.spring(response: 0.3), value: isEnabled)
    }
}

// MARK: - Top Bar

struct StarWalletTopBar: View {
    let balance: Int

    var body: some View {
        HStack {
            Label(balance.asStarMinutesLabel, systemImage: "star.fill")
                .font(Theme.Fonts.childBody(22))
                .foregroundColor(.erYellow)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            Spacer()
        }
        .padding(.horizontal, Theme.Sizing.padding)
        .padding(.vertical, 16)
        .background(Color.erBlue)
    }
}
