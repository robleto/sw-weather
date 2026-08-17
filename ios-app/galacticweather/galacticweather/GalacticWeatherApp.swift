import SwiftUI

@main
struct GalacticWeatherApp: App {
    init() {
        Analytics.start()
        Analytics.track(AnalyticsSignal.appLaunched)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
