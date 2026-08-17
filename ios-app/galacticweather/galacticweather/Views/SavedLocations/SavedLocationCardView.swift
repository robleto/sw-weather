import SwiftUI

/// One full-width panel in the saved-locations list: name and local time on
/// the left, temperature on the right, condition and H/L along the bottom,
/// over that location's own planet art. The art is the point — it's how you
/// recognize a place in the list before you've read the label.
///
/// Two states, because a card has to stay legible before its weather
/// arrives:
/// - `.loading` — name only, over the neutral backdrop
/// - `.ready` — the full readout
///
/// There's deliberately no locked state. Saved locations past the free cap
/// are hidden from the list rather than shown dimmed — see the note on
/// `SavedLocationsView.cards`.
struct SavedLocationCardView: View {
    enum Mode {
        case loading
        case ready(WeatherResponse, ResolvedWorld)
    }

    let name: String
    let mode: Mode

    private var textColor: Color { Color(hex: "#f2f5fa") }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
    }

    var body: some View {
        backdrop
            .frame(height: 132)
            .frame(maxWidth: .infinity)
            .clipShape(shape)
            // The text is an overlay rather than a ZStack sibling of the art
            // on purpose. `backdrop` is a multi-statement ViewBuilder switch,
            // so it reaches a ZStack as one opaque `_ConditionalContent`
            // wrapping a TupleView, and the greedy fill image inside it drew
            // straight over the label. An overlay is unconditionally above.
            .overlay(alignment: .bottomLeading) {
                content
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
            }
            .overlay(shape.strokeBorder(.white.opacity(0.12)))
            // Both of these are load-bearing. `clipShape` only clips drawing,
            // so without them the press target and the lifted context-menu
            // preview are derived from the card's content — including the
            // backdrop image, which overflows the frame to fill it — rather
            // than the rounded rect on screen. That's what made a long-press
            // land on a neighbouring card.
            .contentShape(shape)
            .contentShape(.contextMenuPreview, shape)
            .accessibilityElement(children: .combine)
    }

    /// An explicit `ZStack` so the art's internal layering is defined by the
    /// container rather than by however a bare `TupleView` happens to resolve.
    private var backdrop: some View {
        ZStack {
            switch mode {
            case .ready(_, let world):
                PlanetTheme.background(for: world.planet)
                // Explicit dimensions from a GeometryReader, the same way
                // LocationPreviewView, AtlasView and ContentView.backdropImage
                // do it. A flexible `.frame(maxWidth: .infinity, maxHeight:)`
                // lets aspect-fill report its own width instead of the card's,
                // which left a sliver of the layer beneath showing down one
                // edge — the art is landscape and the card is far wider than
                // tall, so the shortfall is small but visible.
                GeometryReader { geometry in
                    Image(PlanetTheme.imageName(for: world.planet))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.height,
                            alignment: .bottom
                        )
                        .clipped()
                }
                // The art runs bright in places; without this the white type
                // washes out over the lighter planets.
                LinearGradient(
                    colors: [.black.opacity(0.45), .black.opacity(0.15)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            case .loading:
                PlanetTheme.background(for: "default")
                Color.white.opacity(0.06)
            }
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    // PoiretOne for the two display elements — the name and
                    // the temperature — and system for everything small.
                    // It's a hairline geometric face: lovely at 28pt, illegible
                    // at 13 over busy planet art.
                    Text(name)
                        .font(.custom("PoiretOne-Regular", size: 28))
                        .tracking(0.5)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text(subtitleText)
                        .font(.system(size: 13))
                        .foregroundStyle(textColor.opacity(0.7))
                        .lineLimit(1)
                }

                Spacer(minLength: 12)

                trailingTemperature
            }

            Spacer(minLength: 0)

            footer
        }
        .foregroundStyle(textColor)
    }

    /// Always the location's local time, on every card.
    ///
    /// This slot used to give way to the API's own name for a renamed place,
    /// on the theory that a custom label shouldn't hide which spot it really
    /// is. Wrong trade: it made renaming cost you the clock, so renamed cards
    /// stopped matching the rest of the list. The reported name is still
    /// shown where it's actually needed — in the rename dialog itself.
    private var subtitleText: String {
        guard case .ready(let weather, _) = mode else { return "" }
        return weather.localTimeText ?? ""
    }

    @ViewBuilder
    private var trailingTemperature: some View {
        switch mode {
        case .ready(let weather, _):
            Text(AppSettings.shared.temperatureUnit.degreeString(fromKelvin: weather.main.temp))
                .font(.custom("PoiretOne-Regular", size: 52))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        case .loading:
            ProgressView()
                .tint(textColor.opacity(0.6))
                .padding(.top, 8)
        }
    }

    @ViewBuilder
    private var footer: some View {
        switch mode {
        case .ready(let weather, _):
            HStack(alignment: .bottom) {
                Text(weather.weather.first?.description.capitalized ?? "")
                    .font(.system(size: 14))
                    .lineLimit(1)

                Spacer(minLength: 8)

                if let range = highLowText(for: weather) {
                    Text(range)
                        .font(.system(size: 14, weight: .medium))
                        .monospacedDigit()
                }
            }
        case .loading:
            Text("Loading…")
                .font(.system(size: 14))
                .foregroundStyle(textColor.opacity(0.55))
        }
    }

    /// Omitted rather than faked when the API leaves the fields out — a
    /// missing range reads better than "H:—° L:—°".
    private func highLowText(for weather: WeatherResponse) -> String? {
        guard let low = weather.main.tempMin, let high = weather.main.tempMax else { return nil }
        let unit = AppSettings.shared.temperatureUnit
        return "H:\(unit.degreeString(fromKelvin: high))  L:\(unit.degreeString(fromKelvin: low))"
    }
}
