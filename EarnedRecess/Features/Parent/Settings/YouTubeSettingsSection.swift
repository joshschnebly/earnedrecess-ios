import SwiftUI

struct YouTubeSettingsSection: View {
    @ObservedObject var settings: ParentSettings
    let onSave: () -> Void

    @State private var showAddSheet = false

    var body: some View {
        Section {
            Toggle(
                "Allow video search",
                isOn: Binding(
                    get: { settings.allowSearch },
                    set: { settings.allowSearch = $0; onSave() }
                )
            )
            if settings.allowSearch {
                Text("Child can search for videos. Safe search is always strict.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Safe search")
                Spacer()
                Text("Strict (always)")
                    .foregroundColor(.secondary)
            }

        } header: {
            Label("YouTube Settings", systemImage: "play.tv")
        }

        Section {
            ForEach(settings.channelArray) { channel in
                ChannelRow(channel: channel)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            removeChannel(channel)
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
            }

            Button {
                showAddSheet = true
            } label: {
                Label("Add channel…", systemImage: "plus.circle.fill")
                    .foregroundColor(.erBlue)
            }

        } header: {
            Text("Channels")
        } footer: {
            Text("Tap a channel in the video browser to search only that channel's videos.")
        }
        .sheet(isPresented: $showAddSheet) {
            AddChannelSheet { channel in
                addChannel(channel)
                showAddSheet = false
            }
        }
    }

    private func removeChannel(_ channel: StoredChannel) {
        settings.channelArray = settings.channelArray.filter { $0.id != channel.id }
        onSave()
    }

    private func addChannel(_ channel: StoredChannel) {
        guard !settings.channelArray.contains(where: { $0.id == channel.id }) else { return }
        settings.channelArray = settings.channelArray + [channel]
        onSave()
    }
}

// MARK: - Channel row

private struct ChannelRow: View {
    let channel: StoredChannel

    var body: some View {
        HStack(spacing: 12) {
            if let urlString = channel.thumbnailURL,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    iconView
                }
                .frame(width: 36, height: 36)
                .clipShape(Circle())
            } else {
                iconView
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(channel.name)
                    .font(.body)
                Text(channel.id)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var iconView: some View {
        ZStack {
            Circle().fill(Color.erBlue.opacity(0.12))
            Text(channel.icon.isEmpty ? "📺" : channel.icon)
                .font(.system(size: 18))
        }
        .frame(width: 36, height: 36)
    }
}

// MARK: - Add Channel Sheet

private struct AddChannelSheet: View {
    let onConfirm: (StoredChannel) -> Void

    @State private var input: String = ""
    @State private var isResolving = false
    @State private var resolved: StoredChannel? = nil
    @State private var errorMessage: String? = nil
    @Environment(\.dismiss) private var dismiss

    private var hasAPIKey: Bool { !YouTubeKidsService.shared.youTubeAPIKey.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(
                        hasAPIKey ? "@handle or channel URL" : "Channel ID (UC…)",
                        text: $input
                    )
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onChange(of: input) { _, _ in
                        resolved = nil
                        errorMessage = nil
                    }

                    if !hasAPIKey {
                        Text("Add your YouTube API key to look up channels by handle. For now, enter the raw channel ID (starts with UC).")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Find channel")
                } footer: {
                    Text(hasAPIKey
                         ? "Example: @SheriffLabrador or youtube.com/@SheriffLabrador"
                         : "Example: UCXIvAXVdbUDzIFhVwB9RR-g")
                }

                if isResolving {
                    Section {
                        HStack {
                            ProgressView()
                            Text("Looking up channel…")
                                .foregroundColor(.secondary)
                                .padding(.leading, 8)
                        }
                    }
                }

                if let channel = resolved {
                    Section("Preview") {
                        ChannelRow(channel: channel)

                        Button("Add \"\(channel.name)\"") {
                            onConfirm(channel)
                        }
                        .foregroundColor(.erBlue)
                        .fontWeight(.semibold)
                    }
                }

                if let error = errorMessage {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .foregroundColor(.erRed)
                    }
                }
            }
            .navigationTitle("Add Channel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Look up") {
                        Task { await lookupChannel() }
                    }
                    .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty || isResolving)
                }
            }
        }
    }

    @MainActor
    private func lookupChannel() async {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isResolving = true
        resolved = nil
        errorMessage = nil

        let result = await YouTubeKidsService.shared.resolveChannel(input: trimmed)

        isResolving = false

        if let channel = result {
            resolved = channel
        } else if !hasAPIKey {
            errorMessage = "No API key configured. Enter the raw channel ID (24 characters starting with UC)."
        } else {
            errorMessage = "Channel not found. Check the handle or URL and try again."
        }
    }
}
