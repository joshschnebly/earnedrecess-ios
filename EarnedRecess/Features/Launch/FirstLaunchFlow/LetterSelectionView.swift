import SwiftUI

struct LetterSelectionView: View {
    var onComplete: ([String]) -> Void

    @State private var selectedLetters: Set<String> = ["A"]
    @State private var showUppercase: Bool = true

    private var letters: [String] {
        let base = showUppercase
            ? (65...90).map { String(UnicodeScalar($0)!) }   // A-Z
            : (97...122).map { String(UnicodeScalar($0)!) }  // a-z
        return base
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 6)

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("✏️")
                    .font(.system(size: 60))
                    .padding(.top, 32)
                Text("Which letters will \(selectedLetters.isEmpty ? "your child" : "they") practice?")
                    .font(Theme.Fonts.parentHeadline(22))
                    .multilineTextAlignment(.center)
                Text("Start simple — you can add more later in settings.")
                    .font(Theme.Fonts.parentBody())
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            // Uppercase / Lowercase toggle
            Picker("Case", selection: $showUppercase) {
                Text("Uppercase A–Z").tag(true)
                Text("Lowercase a–z").tag(false)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // Letter grid
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(letters, id: \.self) { letter in
                        LetterToggleButton(
                            letter: letter,
                            isSelected: selectedLetters.contains(letter),
                            onTap: { toggle(letter) }
                        )
                    }
                }
                .padding(.horizontal)
            }

            // Quick select
            HStack(spacing: 16) {
                Button("Select All") {
                    selectedLetters = Set(letters)
                }
                .font(Theme.Fonts.parentBody())
                .foregroundColor(.erBlue)

                Button("Clear") {
                    selectedLetters = []
                }
                .font(Theme.Fonts.parentBody())
                .foregroundColor(.erRed)
            }

            Button("Continue with \(selectedLetters.count) letter\(selectedLetters.count == 1 ? "" : "s")") {
                let sorted = selectedLetters.sorted()
                onComplete(sorted.isEmpty ? ["A"] : sorted)
            }
            .buttonStyle(PrimaryButtonStyle(color: .erBlue, isDisabled: selectedLetters.isEmpty))
            .disabled(selectedLetters.isEmpty)
            .padding(.horizontal, Theme.Sizing.padding)
            .padding(.bottom, 32)
        }
        .background(Color.erBackground.ignoresSafeArea())
    }

    private func toggle(_ letter: String) {
        if selectedLetters.contains(letter) {
            selectedLetters.remove(letter)
        } else {
            selectedLetters.insert(letter)
        }
    }
}

struct LetterToggleButton: View {
    let letter: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(letter)
                .font(Theme.Fonts.childBody(24))
                .frame(width: 52, height: 52)
                .background(isSelected ? Color.erBlue : Color.erCard)
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(12)
                .cardShadow()
                .scaleEffect(isSelected ? 1.05 : 1.0)
                .animation(.spring(response: 0.2), value: isSelected)
        }
    }
}
