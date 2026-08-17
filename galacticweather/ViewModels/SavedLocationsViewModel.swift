import Foundation
import Observation

/// Owns the user's saved locations and their persistence. Same shape as
/// `AtlasViewModel`: a synchronous first read, plus a remote-change
/// observer for when another device edits the list via iCloud.
@Observable
final class SavedLocationsViewModel {
    private(set) var locations: [SavedLocation]

    @ObservationIgnored private var remoteChangeObserver: NSObjectProtocol?

    init() {
        locations = SavedLocationsStorage.load()
        SavedLocationsStorage.startSync()
        remoteChangeObserver = SavedLocationsStorage.observeRemoteChanges { [weak self] merged in
            self?.locations = merged
        }
    }

    deinit {
        if let remoteChangeObserver {
            NotificationCenter.default.removeObserver(remoteChangeObserver)
        }
    }

    @MainActor var canSaveMore: Bool { locations.count < PremiumGate.maxSavedLocations }

    func isSaved(lat: Double, lon: Double) -> Bool {
        let id = SavedLocation.id(lat: lat, lon: lon)
        return locations.contains { $0.id == id }
    }

    /// Adding is gated on premium + the list cap; removing an existing entry
    /// never is, so a lapsed/refunded purchase still lets someone clean up
    /// their list rather than getting stuck with it.
    @MainActor
    func toggleSaved(displayName: String, lat: Double, lon: Double) {
        let id = SavedLocation.id(lat: lat, lon: lon)
        if let index = locations.firstIndex(where: { $0.id == id }) {
            locations.remove(at: index)
            SavedLocationsStorage.save(locations)
            return
        }
        guard PremiumGate.canUseSavedLocations, canSaveMore else { return }
        locations.append(SavedLocation(displayName: displayName, lat: lat, lon: lon))
        SavedLocationsStorage.save(locations)
    }

    func remove(_ location: SavedLocation) {
        locations.removeAll { $0.id == location.id }
        SavedLocationsStorage.save(locations)
    }
}
