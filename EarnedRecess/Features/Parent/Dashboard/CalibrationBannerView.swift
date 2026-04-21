import SwiftUI

struct CalibrationBannerView: View {
    let suggestion: CalibrationSuggestion
    let onAdjustNow: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.orange)
                .font(.system(size: 20))
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 8) {
                Text(suggestion.message)
                    .font(Theme.Fonts.parentBody())
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 12) {
                    Button("Adjust Now", action: onAdjustNow)
                        .font(Theme.Fonts.parentBody())
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.orange)
                        .cornerRadius(8)

                    Button("Dismiss", action: onDismiss)
                        .font(Theme.Fonts.parentBody())
                        .foregroundColor(.orange)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.15))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Sizing.cardCornerRadius)
                .stroke(Color.orange, lineWidth: 1)
        )
        .cornerRadius(Theme.Sizing.cardCornerRadius)
        .padding(.horizontal)
        .padding(.top, 8)
    }
}
