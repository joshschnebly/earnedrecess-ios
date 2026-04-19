import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState

    @State private var selectedTab: DashTab = .overview

    enum DashTab: String, CaseIterable {
        case overview  = "Overview"
        case letters   = "Letters"
        case history   = "History"
        case watchTime = "Watch Time"

        var icon: String {
            switch self {
            case .overview:  return "chart.bar.fill"
            case .letters:   return "textformat"
            case .history:   return "clock.fill"
            case .watchTime: return "play.tv.fill"
            }
        }
    }

    var body: some View {
        Group {
            if let child = appState.currentChild,
               let settings = appState.parentSettings {
                VStack(spacing: 0) {
                    // Custom segmented picker (4 tabs don't fit default segmented well on iPad)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(DashTab.allCases, id: \.self) { tab in
                                DashTabButton(
                                    tab: tab,
                                    isSelected: selectedTab == tab,
                                    onTap: { withAnimation(.spring(response: 0.3)) { selectedTab = tab } }
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                    }
                    .background(Color.erCard)

                    Divider()

                    // Tab content
                    switch selectedTab {
                    case .overview:
                        OverviewTab(child: child)
                    case .letters:
                        LettersTab(child: child, settings: settings)
                    case .history:
                        HistoryTab(child: child)
                    case .watchTime:
                        WatchTimeTab(child: child)
                    }
                }
            } else {
                ProgressView("Loading…")
            }
        }
    }
}

struct DashTabButton: View {
    let tab: DashboardView.DashTab
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: tab.icon)
                Text(tab.rawValue)
                    .font(Theme.Fonts.parentBody())
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.erBlue : Color.erBackground)
            .cornerRadius(20)
        }
    }
}
