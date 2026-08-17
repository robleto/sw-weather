import SwiftUI

/// The landed-state weather text block. Renders nothing at all until weather
/// data has loaded, matching the original's early return. The planet backdrop
/// image is rendered separately by `ContentView` so this view can be pinned
/// to the top half of the screen independent of the full-bleed photo.
struct WeatherDetailsView: View {
    /// Passed in rather than read off the view model: each swipeable page
    /// renders its own location's weather, so there is no single "current"
    /// value to reach for.
    var weatherData: WeatherResponse
    var weatherInfo: ResolvedWorld
    /// Shown instead of `weatherData.name`, so a renamed saved location keeps
    /// its user-chosen label here too.
    var locationName: String
    /// Optional short status shown directly under the location line. The
    /// preview screen uses it for "Not saved" — without it that screen is
    /// pixel-identical to a real page apart from its two buttons.
    var badge: String?

    var body: some View {
        let info = weatherInfo
        // This text sits directly on the planet photo, so it uses the world's
        // measured textColor rather than color.headline — see TextTone.
        let headline = Color(hex: info.textColor)

            VStack(spacing: 10) {
                Text("Today's Forecast for \(locationName)")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1.5)
                    .textCase(.uppercase)
                    .foregroundStyle(headline.opacity(0.78))

                if let badge {
                    Text(badge)
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1.4)
                        .textCase(.uppercase)
                        .foregroundStyle(headline)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(headline.opacity(0.14)))
                        .overlay(Capsule().strokeBorder(headline.opacity(0.35)))
                }

                Text(temperatureLine(for: weatherData))
                    .font(.custom("PoiretOne-Regular", size: 42))
                    .foregroundStyle(headline)

                Text("\(locationName) feels like being on")
                    .font(.system(size: 13))
                    .tracking(1.5)
                    .textCase(.uppercase)
                    .foregroundStyle(headline.opacity(0.78))

                Text(info.planetName)
                    // The one that gains most from the swap: PoiretOne is an
                    // Art Deco face, and uppercase with this much tracking is
                    // exactly what it's drawn for.
                    .font(.custom("PoiretOne-Regular", size: 56))
                    .tracking(3)
                    .textCase(.uppercase)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(headline)

                Text(info.description)
                    .font(.system(size: 16))
                    .lineSpacing(4)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(headline.opacity(0.78))
                    .frame(maxWidth: 480)
            }
            .padding(.horizontal, 24)
    }

    /// The one place that spells the unit out rather than showing a bare
    /// degree sign — it's the app's headline reading, and "76°F and Clouds"
    /// reads as a sentence in a way "76° and Clouds" doesn't.
    private func temperatureLine(for weatherData: WeatherResponse) -> String {
        let unit = AppSettings.shared.temperatureUnit
        let degrees = unit.degrees(fromKelvin: weatherData.main.temp)
        let condition = weatherData.weather.first?.main ?? ""
        return "\(degrees)\u{00B0}\(unit.symbol) and \(condition)"
    }
}
