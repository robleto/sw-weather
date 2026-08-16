import SwiftUI

/// A tiny reusable pill that marks a locked, premium-only affordance.
///
/// Used by Star Chart rows and the locked location-search field. Sized to
/// drop straight into an `HStack` alongside other row content — it does not
/// force its own width or add a `Spacer`, so the caller controls layout.
struct PremiumLockChip: View {
    var text: String = "Premium"

    init(text: String = "Premium") {
        self.text = text
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.fill")
                .font(.system(size: 9, weight: .semibold))
            Text(text)
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.6)
                .textCase(.uppercase)
        }
        .foregroundStyle(Color(hex: "#8fc7ff"))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.14))
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        )
    }
}

#Preview {
    ZStack {
        Color(hex: "#0a0e16").ignoresSafeArea()
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Ord Mantell")
                    .foregroundStyle(Color(hex: "#f2f5fa"))
                Spacer()
                PremiumLockChip()
            }
            HStack {
                Text("Search a city")
                    .foregroundStyle(Color(hex: "#f2f5fa"))
                Spacer()
                PremiumLockChip(text: "Any City")
            }
        }
        .padding()
    }
}
