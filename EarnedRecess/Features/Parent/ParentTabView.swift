import SwiftUI

struct ParentTabView: View {
    @EnvironmentObject var appState: AppState
    let onExitToChild: () -> Void

    @State private var selectedTab: Tab = .dashboard

    enum Tab { case dashboard, settings, exit }

    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard — Sessions 16 & 17
            NavigationStack {
                DashboardView()
                    .navigationTitle("Dashboard")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem { Label("Dashboard", systemImage: "chart.bar.fill") }
            .tag(Tab.dashboard)

            // Settings — Session 15
            NavigationStack {
                ParentSettingsView()
                    .navigationTitle("Settings")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem { Label("Settings", systemImage: "gear") }
            .tag(Tab.settings)

            // Exit to child
            exitTab
                .tabItem { Label("Exit to Child", systemImage: "person.fill") }
                .tag(Tab.exit)
        }
        .tint(.erBlue)
        .onChange(of: selectedTab) { tab in
            if tab == .exit { confirmExit() }
        }
    }

    private var exitTab: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "arrow.left.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.erBlue)

            Text("Return to Child Mode")
                .font(Theme.Fonts.parentHeadline(24))

            // Guided Access reminder
            if !GuidedAccessService.isEnabled {
                VStack(spacing: 8) {
                    Label("Guided Access is OFF", systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.erOrange)
                        .font(Theme.Fonts.parentBody())

                    Text("Enable Guided Access before handing the iPad to your child.")
                        .font(Theme.Fonts.parentBody())
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
                .background(Color.erOrange.opacity(0.1))
                .cornerRadius(Theme.Sizing.cardCornerRadius)
                .padding(.horizontal)
            }

            Button("Hand to \(appState.currentChild?.name ?? "Child")") {
                confirmExit()
            }
            .buttonStyle(PrimaryButtonStyle(color: .erGreen))
            .padding(.horizontal, Theme.Sizing.padding)

            Spacer()
        }
        .background(Color.erBackground.ignoresSafeArea())
    }

    private func confirmExit() {
        appState.isParentSessionActive = false
        onExitToChild()
    }
}
