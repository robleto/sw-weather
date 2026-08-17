import SwiftUI

/// Attribution and links. This content used to live in a bottom bar on the
/// landed screen (`FooterView`), which was orphaned when the layout moved to
/// full-bleed planet art — it now has a home in the menu instead.
struct CreditsView: View {
    private struct IconLink: Identifiable {
        let id: String
        let label: String
        let imageName: String
        let url: URL
    }

    private static let iconLinks: [IconLink] = [
        IconLink(id: "website", label: "robleto.com", imageName: "website-icon", url: URL(string: "https://www.robleto.com")!),
        IconLink(id: "codepen", label: "CodePen", imageName: "codepen-icon", url: URL(string: "https://www.codepen.com/robleto")!),
        IconLink(id: "dribbble", label: "Dribbble", imageName: "dribbble-icon", url: URL(string: "https://www.dribbble.com/robleto")!),
        IconLink(id: "github", label: "GitHub", imageName: "github-icon", url: URL(string: "https://www.github.com/robleto")!),
        IconLink(id: "linkedin", label: "LinkedIn", imageName: "linkedin-icon", url: URL(string: "https://www.linkedin.com/in/robleto")!)
    ]

    var body: some View {
        MenuScreen(eyebrow: "CREDITS", title: "Made by hand") {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(inspiredLine)
                        .font(.system(size: 14))
                    Text(developedByLine)
                        .font(.system(size: 14))
                }
                .tint(Color(hex: "#8fc7ff"))
                .foregroundStyle(Color(hex: "#f2f5fa").opacity(0.75))

                VStack(alignment: .leading, spacing: 8) {
                    Text("ELSEWHERE")
                        .font(.system(size: 11, weight: .medium))
                        .tracking(1.4)
                        .foregroundStyle(.white.opacity(0.45))

                    ForEach(Self.iconLinks) { icon in
                        Link(destination: icon.url) {
                            HStack(spacing: 12) {
                                Image(icon.imageName)
                                    .renderingMode(.template)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 18, height: 18)
                                    .foregroundStyle(Color(hex: "#8fc7ff"))

                                Text(icon.label)
                                    .font(.system(size: 15))
                                    .foregroundStyle(Color(hex: "#f2f5fa"))

                                Spacer(minLength: 8)

                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.35))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(.white.opacity(0.05))
                            )
                        }
                    }
                }

                Text("Planet artwork is original. World names are used affectionately, not officially.")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
    }

    private var inspiredLine: AttributedString {
        var result = AttributedString("Inspired by a ")
        var link = AttributedString("weather site")
        link.link = URL(string: "https://www.tomscott.com/weather/starwars/")
        link.underlineStyle = .single
        result += link
        result += AttributedString(" from long ago.")
        return result
    }

    private var developedByLine: AttributedString {
        var result = AttributedString("Designed and developed by ")
        var link = AttributedString("Greg Robleto")
        link.link = URL(string: "https://www.robleto.com/")
        link.underlineStyle = .single
        result += link
        result += AttributedString(".")
        return result
    }
}

#Preview {
    CreditsView()
}
