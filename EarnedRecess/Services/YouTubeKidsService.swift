import Foundation

// MARK: - Models

struct YouTubeVideo: Identifiable, Equatable {
    let id: String
    let title: String
    let channelName: String
    let thumbnailURL: URL?
    let duration: String?
}

struct YouTubeChannel: Identifiable {
    let id: String
    let name: String
    let icon: String
}

// MARK: - Service

class YouTubeKidsService: ObservableObject {
    static let shared = YouTubeKidsService()
    private init() {}

    let featuredChannels: [YouTubeChannel] = [
        YouTubeChannel(id: "UCbCmjCuTUZos6Inko4u57UQ", name: "Bluey",      icon: "🐕"),
        YouTubeChannel(id: "UCAOtE1V7Ots4twtDCWhpHYg", name: "Peppa Pig",  icon: "🐷"),
        YouTubeChannel(id: "UCF2M_-q5oKF8cHk1KWo9gkA", name: "Paw Patrol", icon: "🐾"),
        YouTubeChannel(id: "UCbCmjCuTUZos6Inko4u57UQ", name: "Cocomelon",  icon: "🍉"),
    ]

    // MARK: - Search

    func searchVideos(query: String = "cartoons for kids",
                      channelId: String? = nil,
                      maxResults: Int = Constants.YouTube.defaultMaxResults) async -> [YouTubeVideo] {
        let key = youTubeAPIKey
        guard !key.isEmpty else {
            return mockVideos(for: query)
        }

        var components = URLComponents(string: "https://www.googleapis.com/youtube/v3/search")!
        var params: [URLQueryItem] = [
            URLQueryItem(name: "part",       value: "snippet"),
            URLQueryItem(name: "type",       value: "video"),
            URLQueryItem(name: "safeSearch", value: Constants.YouTube.safeSearchLevel),
            URLQueryItem(name: "maxResults", value: "\(maxResults)"),
            URLQueryItem(name: "key",        value: key),
            URLQueryItem(name: "q",          value: query),
        ]
        if let channelId { params.append(URLQueryItem(name: "channelId", value: channelId)) }
        components.queryItems = params

        guard let url = components.url else { return [] }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(YouTubeSearchResponse.self, from: data)
            return response.items.map { item in
                YouTubeVideo(
                    id: item.id.videoId,
                    title: item.snippet.title,
                    channelName: item.snippet.channelTitle,
                    thumbnailURL: URL(string: item.snippet.thumbnails.medium.url),
                    duration: nil
                )
            }
        } catch {
            print("YouTubeKidsService error: \(error)")
            return mockVideos(for: query)
        }
    }

    // MARK: - API key
    // Reads from Secrets.swift (gitignored). Falls back to mock data until key is added.
    // Create EarnedRecess/Resources/Secrets.swift:
    //   enum Secrets { static let youTubeAPIKey = "YOUR_KEY" }
    // Then delete the YoutubeAPIKey extension at bottom of this file.

    private var youTubeAPIKey: String {
        YoutubeAPIKey.value
    }

    // MARK: - Mock data

    func mockVideos(for query: String) -> [YouTubeVideo] {
        let titles = [
            "Bluey - Dad Baby", "Peppa Pig Full Episodes", "Paw Patrol Rescue",
            "Cocomelon Nursery Rhymes", "Bluey - The Creek", "Peppa Pig Swimming",
            "PAW Patrol Sea Patrol", "Baby Shark Dance", "Bluey - Markets",
            "Peppa Pig Fancy Dress", "Paw Patrol Jungle", "Five Little Monkeys",
        ]
        return titles.enumerated().map { i, title in
            YouTubeVideo(id: "mock_\(i)", title: title,
                         channelName: ["Bluey Official","Peppa Pig","PAW Patrol"][i % 3],
                         thumbnailURL: nil, duration: nil)
        }
    }
}

// MARK: - Codable response models

private struct YouTubeSearchResponse: Codable {
    let items: [SearchItem]
    struct SearchItem: Codable { let id: VideoId; let snippet: Snippet }
    struct VideoId: Codable { let videoId: String }
    struct Snippet: Codable {
        let title: String
        let channelTitle: String
        let thumbnails: Thumbnails
    }
    struct Thumbnails: Codable { let medium: ThumbnailInfo }
    struct ThumbnailInfo: Codable { let url: String }
}

// MARK: - API key stub
// DELETE this enum once you create EarnedRecess/Resources/Secrets.swift

private enum YoutubeAPIKey {
    // Replace with: static let value = Secrets.youTubeAPIKey
    static let value: String = ""
}
