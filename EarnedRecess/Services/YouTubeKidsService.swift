import Foundation

// MARK: - Models

struct YouTubeVideo: Identifiable, Equatable {
    let id: String
    let title: String
    let channelName: String
    let thumbnailURL: URL?
    let duration: String?
}

/// Lightweight channel model used in the video browser UI.
struct YouTubeChannel: Identifiable, Equatable {
    let id: String
    let name: String
    let icon: String           // emoji for built-in channels; empty for user-added
    let thumbnailURL: URL?     // set when resolved via API
}

/// Codable channel stored in ParentSettings.youtubeChannelWhitelist (JSON array).
struct StoredChannel: Codable, Equatable, Identifiable {
    let id: String
    let name: String
    let icon: String
    var thumbnailURL: String?

    var asChannel: YouTubeChannel {
        YouTubeChannel(id: id, name: name, icon: icon,
                       thumbnailURL: thumbnailURL.flatMap(URL.init))
    }
}

// MARK: - Service

final class YouTubeKidsService {
    static let shared = YouTubeKidsService()
    private init() {}

    // MARK: - Search

    func searchVideos(query: String = "cartoons for kids",
                      channelId: String? = nil,
                      maxResults: Int = Constants.YouTube.defaultMaxResults) async -> [YouTubeVideo] {
        let key = youTubeAPIKey
        guard !key.isEmpty else { return mockVideos(for: query) }

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
            print("[EarnedRecess] YouTubeKidsService.searchVideos error: \(error)")
            return mockVideos(for: query)
        }
    }

    // MARK: - Channel Resolution

    /// Resolves a YouTube handle, URL, or raw channel ID into a StoredChannel.
    /// Accepts: @SheriffLabrador, youtube.com/@SheriffLabrador, UCxxxxxxx, full URLs.
    /// Returns nil if the API call fails or the key is absent (caller shows fallback UI).
    func resolveChannel(input: String) async -> StoredChannel? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let key = youTubeAPIKey

        // Determine if input is already a raw channel ID (starts with UC and ~24 chars)
        let rawId = extractChannelId(from: trimmed)

        // No API key — return a stub with whatever ID we could extract
        guard !key.isEmpty else {
            guard let id = rawId else { return nil }
            return StoredChannel(id: id, name: "Unknown channel", icon: "", thumbnailURL: nil)
        }

        // Try channels endpoint with forHandle (cheapest: 1 unit)
        if let handle = extractHandle(from: trimmed) {
            if let ch = await fetchChannel(param: URLQueryItem(name: "forHandle", value: handle), key: key) { return ch }
        }

        // Fallback: raw UC… channel ID
        if let id = rawId {
            if let ch = await fetchChannel(param: URLQueryItem(name: "id", value: id), key: key) { return ch }
        }

        return nil
    }

    // MARK: - Private: Channel lookup helpers

    private func extractHandle(from input: String) -> String? {
        if input.hasPrefix("@") { return String(input.dropFirst()) }
        let urlString = input.hasPrefix("http") ? input : "https://\(input)"
        guard let url = URL(string: urlString),
              url.host?.contains("youtube.com") == true,
              url.path.hasPrefix("/@") else { return nil }
        return String(url.path.dropFirst(2))
    }

    private func extractChannelId(from input: String) -> String? {
        if input.hasPrefix("UC") && input.count == 24 { return input }
        if let range = input.range(of: "/channel/") {
            let id = String(input[range.upperBound...].prefix(24))
            if id.hasPrefix("UC") { return id }
        }
        return nil
    }

    private func fetchChannel(param: URLQueryItem, key: String) async -> StoredChannel? {
        guard var components = URLComponents(string: "https://www.googleapis.com/youtube/v3/channels") else { return nil }
        components.queryItems = [
            URLQueryItem(name: "part", value: "snippet"),
            param,
            URLQueryItem(name: "key",  value: key),
        ]
        guard let url = components.url else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(ChannelListResponse.self, from: data)
            guard let item = response.items.first else { return nil }
            let thumb = item.snippet.thumbnails.default?.url
            return StoredChannel(id: item.id, name: item.snippet.title, icon: "", thumbnailURL: thumb)
        } catch {
            print("[EarnedRecess] resolveChannel error: \(error)")
            return nil
        }
    }

    // MARK: - API key
    // Reads from Secrets.swift (gitignored). Falls back to mock data until key is added.
    // Create EarnedRecess/Resources/Secrets.swift:
    //   enum Secrets { static let youTubeAPIKey = "YOUR_KEY" }
    // Then replace the stub below with: static let value = Secrets.youTubeAPIKey

    var youTubeAPIKey: String { YoutubeAPIKey.value }

    // MARK: - Mock data

    func mockVideos(for query: String) -> [YouTubeVideo] {
        let titles = [
            "Peppa Pig Full Episodes", "Paw Patrol Rescue", "JunyTony Colors",
            "Pit & Penny Adventures", "Sheriff Labrador & Friends", "Disney Junior Minnie",
            "Peppa Pig Swimming", "PAW Patrol Sea Patrol", "JunyTony Numbers",
            "Pit & Penny Beach Day", "Sheriff Labrador Case", "Minnie Bowtique",
        ]
        let channels = ["Peppa Pig", "PAW Patrol", "JunyTony", "Pit & Penny",
                        "Sheriff Labrador", "Disney Junior"]
        return titles.enumerated().map { i, title in
            YouTubeVideo(id: "mock_\(i)", title: title,
                         channelName: channels[i % channels.count],
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

private struct ChannelListResponse: Codable {
    let items: [ChannelItem]
    struct ChannelItem: Codable {
        let id: String
        let snippet: Snippet
    }
    struct Snippet: Codable {
        let title: String
        let thumbnails: Thumbnails
    }
    struct Thumbnails: Codable { let `default`: ThumbnailInfo? }
    struct ThumbnailInfo: Codable { let url: String }
}

// MARK: - API key stub
// DELETE this enum once you create EarnedRecess/Resources/Secrets.swift

private enum YoutubeAPIKey {
    // Replace with: static let value = Secrets.youTubeAPIKey
    static let value: String = ""
}
