import SwiftUI

struct VideoThumbnailView: View {
    let video: YouTubeVideo
    let onTap: () -> Void

    @State private var imageLoaded = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Thumbnail image
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.erBlue.opacity(0.15))
                        .aspectRatio(16/9, contentMode: .fit)

                    if let url = video.thumbnailURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .opacity(imageLoaded ? 1 : 0)
                                    .onAppear {
                                        withAnimation(.easeIn(duration: 0.2)) { imageLoaded = true }
                                    }
                            case .failure:
                                thumbnailFallback
                            case .empty:
                                ProgressView()
                                    .tint(.erBlue)
                            @unknown default:
                                thumbnailFallback
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        thumbnailFallback
                    }

                    // Play button overlay
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.white.opacity(0.9))
                        .shadow(radius: 4)
                }
                .aspectRatio(16/9, contentMode: .fit)

                // Title
                Text(video.title)
                    .font(Theme.Fonts.childCaption(14))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // Channel name
                Text(video.channelName)
                    .font(Theme.Fonts.childCaption(12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }

    private var thumbnailFallback: some View {
        VStack(spacing: 8) {
            Image(systemName: "play.tv")
                .font(.system(size: 32))
                .foregroundColor(.erBlue.opacity(0.5))
            Text(video.title)
                .font(Theme.Fonts.childCaption(11))
                .foregroundColor(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 4)
        }
    }
}
