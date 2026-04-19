import SwiftUI

struct YouTubeSettingsSection: View {
    @ObservedObject var settings: ParentSettings
    let onSave: () -> Void

    @State private var newChannelId: String = ""
    @State private var showAddChannel = false

    private var whitelist: [String] { settings.channelWhitelistArray }

    var body: some View {
        Section {
            // Allow search toggle
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

            // Channel whitelist
            DisclosureGroup("Channel whitelist (\(whitelist.count))") {
                ForEach(whitelist, id: \.self) { channelId in
                    HStack {
                        Image(systemName: "play.rectangle")
                            .foregroundColor(.erBlue)
                        Text(channelId)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                        Spacer()
                        Button(role: .destructive) {
                            removeChannel(channelId)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.erRed)
                        }
                    }
                }

                // Add new channel
                if showAddChannel {
                    HStack {
                        TextField("YouTube Channel ID", text: $newChannelId)
                            .font(.system(.body, design: .monospaced))
                            .autocorrectionDisabled()
                        Button("Add") {
                            addChannel()
                        }
                        .disabled(newChannelId.trimmingCharacters(in: .whitespaces).isEmpty)
                        .foregroundColor(.erBlue)
                    }
                }

                Button(action: { showAddChannel.toggle() }) {
                    Label(showAddChannel ? "Cancel" : "Add Channel ID", systemImage: showAddChannel ? "xmark" : "plus")
                }
                .foregroundColor(.erBlue)
            }

            // Safe search info
            HStack {
                Text("Safe search level")
                Spacer()
                Text("Strict (always)")
                    .foregroundColor(.secondary)
            }

        } header: {
            Label("YouTube Settings", systemImage: "play.tv")
        } footer: {
            Text("Channel IDs can be found in a channel's YouTube URL.")
        }
    }

    private func addChannel() {
        let id = newChannelId.trimmingCharacters(in: .whitespaces)
        guard !id.isEmpty, !whitelist.contains(id) else { return }
        var updated = whitelist
        updated.append(id)
        settings.channelWhitelistArray = updated
        newChannelId = ""
        showAddChannel = false
        onSave()
    }

    private func removeChannel(_ id: String) {
        settings.channelWhitelistArray = whitelist.filter { $0 != id }
        onSave()
    }
}
