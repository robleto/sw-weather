import SwiftUI

/// Bottom bar shown only in the landed state: attribution lines plus a row
/// of social icon links.
struct FooterView: View {
    private struct IconLink: Identifiable {
        let id: String
        let imageName: String
        let url: URL
    }

    private static let iconLinks: [IconLink] = [
        IconLink(id: "website", imageName: "website-icon", url: URL(string: "https://www.robleto.com")!),
        IconLink(id: "codepen", imageName: "codepen-icon", url: URL(string: "https://www.codepen.com/robleto")!),
        IconLink(id: "dribbble", imageName: "dribbble-icon", url: URL(string: "https://www.dribbble.com/robleto")!),
        IconLink(id: "github", imageName: "github-icon", url: URL(string: "https://www.github.com/robleto")!),
        IconLink(id: "linkedin", imageName: "linkedin-icon", url: URL(string: "https://www.linkedin.com/in/robleto")!)
    ]

    var body: some View {
        VStack(spacing: 6) {
            Text(inspiredLine)
                .font(.system(size: 13))

            Text(developedByLine)
                .font(.system(size: 13))

            HStack(spacing: 4) {
                ForEach(Self.iconLinks) { icon in
                    Link(destination: icon.url) {
                        Image(icon.imageName)
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .frame(width: 44, height: 44)
                    }
                }
            }
        }
        .tint(.white)
        .foregroundStyle(Color.white.opacity(0.65))
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.95))
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
        return result
    }
}

#Preview {
    FooterView()
}
