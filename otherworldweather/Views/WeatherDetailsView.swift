import SwiftUI

/// The landed-state weather text block. Renders nothing at all until weather
/// data has loaded, matching the original's early return. The planet backdrop
/// image is rendered separately by `ContentView` so this view can be pinned
/// to the top half of the screen independent of the full-bleed photo.
struct WeatherDetailsView: View {
    var weatherViewModel: WeatherViewModel

    var body: some View {
        if let weatherData = weatherViewModel.weatherData {
            let info = weatherViewModel.weatherInfo
            let headline = Color(hex: info.color.headline)

            VStack(spacing: 10) {
                Text("Today's Forecast for \(weatherData.name)")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1.5)
                    .textCase(.uppercase)
                    .foregroundStyle(headline.opacity(0.78))

                Text(temperatureLine(for: weatherData))
                    .font(.custom("RussoOne-Regular", size: 36))
                    .foregroundStyle(headline)

                Text("Today's Weather Twin")
                    .font(.system(size: 13))
                    .tracking(1.5)
                    .textCase(.uppercase)
                    .foregroundStyle(headline.opacity(0.78))

                Text(info.planetName)
                    .font(.custom("RussoOne-Regular", size: 48))
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
        } else {
            EmptyView()
        }
    }

    private func temperatureLine(for weatherData: WeatherResponse) -> String {
        let fahrenheit = Int(kelvinToFahrenheit(weatherData.main.temp).rounded())
        let condition = weatherData.weather.first?.main ?? ""
        return "\(fahrenheit)\u{00B0}F and \(condition)"
    }
}
