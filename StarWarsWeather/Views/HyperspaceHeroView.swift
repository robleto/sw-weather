import SwiftUI

/// The idle-state hero text, pinned to the top half of the screen over the
/// hyperspace star field: eyebrow line, display heading, and subtext. The
/// location search field lives in `ContentView`'s bottom-docked bar instead
/// of here, so this view only owns the copy above it.
struct HyperspaceHeroView: View {
    var pageError: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Somewhere out there, it feels just like this…")
                .font(.system(size: 12, weight: .medium))
                .tracking(2.5)
                .textCase(.uppercase)
                .foregroundStyle(Color(hex: "#a0c8ff").opacity(0.65))

            Text("Where in the galaxy are you?")
                .font(.custom("RussoOne-Regular", size: 40))
                .tracking(1.5)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(hex: "#e8f4ff"))
                .shadow(color: Color(hex: "#64a0ff").opacity(0.55), radius: 24)

            Text("Enter your location to discover today's weather twin")
                .font(.system(size: 16))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(hex: "#c8dcff").opacity(0.6))

            if let pageError {
                Text(pageError)
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "#ffd4d4"))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: 560)
    }
}
