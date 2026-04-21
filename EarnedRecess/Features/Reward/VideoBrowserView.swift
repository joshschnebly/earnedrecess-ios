import SwiftUI

struct VideoBrowserView: View {
    @EnvironmentObject var appState: AppState
    let onSelectVideo: (YouTubeVideo) -> Void
    let onStop: () -> Void

    private let service = YouTubeKidsService.shared
    @State private var videos: [YouTubeVideo] = []
    @State private var isLoading = false
    @State private var searchQuery = ""
    @State private var selectedChannelId: String? = nil
    @State private var showSearch = false
    @State private var pendingVideo: YouTubeVideo? = nil

    private var allowSearch: Bool {
        appState.parentSettings?.allowSearch ?? false
    }

    @Environment(\.horizontalSizeClass) var sizeClass

    private var requiresWriteToWatch: Bool {
        let mode = appState.parentSettings?.appModeEnum ?? .standard
        return mode == .writeToWatch || mode == .both
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 16), count: sizeClass == .regular ? 4 : 3)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Timer bar
            RewardTimerBar(timer: appState.rewardTimer, onStop: onStop)

            // Channel quick-picks
            channelBar

            // Search bar (if parent enabled)
            if showSearch && allowSearch {
                searchBar
            }

            // Video grid
            ZStack {
                if isLoading {
                    loadingView
                } else if videos.isEmpty {
                    emptyView
                } else {
                    videoGrid
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.erBackground.ignoresSafeArea())
        .task { await loadVideos() }
        .fullScreenCover(item: $pendingVideo) { video in
            WriteToWatchView(
                videoTitle: video.title,
                onSuccess: {
                    pendingVideo = nil
                    onSelectVideo(video)
                },
                onCancel: {
                    pendingVideo = nil
                }
            )
            .environmentObject(appState)
        }
    }

    // MARK: - Sub-views

    private var channelBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // "All" button
                ChannelChip(
                    label: "🎬 All",
                    isSelected: selectedChannelId == nil,
                    onTap: {
                        selectedChannelId = nil
                        Task { await loadVideos() }
                    }
                )

                ForEach(appState.parentSettings?.channelArray ?? Constants.YouTube.defaultChannels) { channel in
                    ChannelChip(
                        label: "\(channel.icon.isEmpty ? "📺" : channel.icon) \(channel.name)",
                        isSelected: selectedChannelId == channel.id,
                        onTap: {
                            selectedChannelId = channel.id
                            Task { await loadVideos(channelId: channel.id) }
                        }
                    )
                }

                if allowSearch {
                    ChannelChip(
                        label: "🔍 Search",
                        isSelected: showSearch,
                        onTap: { withAnimation { showSearch.toggle() } }
                    )
                }
            }
            .padding(.horizontal, Theme.Sizing.padding)
            .padding(.vertical, 10)
        }
        .background(Color.erCard)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search videos...", text: $searchQuery)
                .font(Theme.Fonts.parentBody())
                .submitLabel(.search)
                .onSubmit {
                    Task { await loadVideos() }
                }
            if !searchQuery.isEmpty {
                Button(action: {
                    searchQuery = ""
                    Task { await loadVideos() }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color.erCard)
        .cornerRadius(10)
        .padding(.horizontal, Theme.Sizing.padding)
        .padding(.bottom, 8)
    }

    private var videoGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(videos) { video in
                    VideoThumbnailView(video: video) {
                        if requiresWriteToWatch {
                            pendingVideo = video
                        } else {
                            onSelectVideo(video)
                        }
                    }
                }
            }
            .padding(Theme.Sizing.padding)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.erBlue)
            Text("Finding videos...")
                .font(Theme.Fonts.childBody())
                .foregroundColor(.secondary)
        }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tv.slash")
                .font(.system(size: 60))
                .foregroundColor(.erBlue.opacity(0.4))
            Text("No videos found")
                .font(Theme.Fonts.childBody())
                .foregroundColor(.secondary)
            Button("Try Again") {
                Task { await loadVideos() }
            }
            .font(Theme.Fonts.parentBody())
            .foregroundColor(.erBlue)
        }
    }

    // MARK: - Data loading

    private func loadVideos(channelId: String? = nil) async {
        isLoading = true
        let query = searchQuery.isEmpty ? "cartoons for kids" : searchQuery
        let channel = channelId ?? selectedChannelId
        videos = await YouTubeKidsService.shared.searchVideos(query: query, channelId: channel)
        isLoading = false
    }
}

// MARK: - Channel chip button

struct ChannelChip: View {
    let label: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(Theme.Fonts.childCaption(15))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.erBlue : Color.erBackground)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.clear : Color.gray.opacity(0.25), lineWidth: 1)
                )
        }
        .animation(.spring(response: 0.25), value: isSelected)
    }
}
