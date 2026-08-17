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

    /// The saved locations this user may actually use right now — the first
    /// `PremiumGate.maxSavedLocations` of them. These are the ones that become
    /// pages in the pager.
    @MainActor
    var unlockedLocations: [SavedLocation] {
        Array(locations.prefix(PremiumGate.maxSavedLocations))
    }

    /// Everything past the cap: still stored, still listed, but dormant until
    /// they subscribe. See `PremiumGate.isSavedLocationUnlocked(index:)`.
    @MainActor
    var lockedLocations: [SavedLocation] {
        Array(locations.dropFirst(PremiumGate.maxSavedLocations))
    }

    func isSaved(lat: Double, lon: Double) -> Bool {
        let id = SavedLocation.id(lat: lat, lon: lon)
        return locations.contains { $0.id == id }
    }

    /// Adding is gated on the tier's list cap; removing an existing entry
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
        guard canSaveMore else { return }
        locations.append(SavedLocation(displayName: displayName, lat: lat, lon: lon))
        SavedLocationsStorage.save(locations)
    }

    func remove(_ location: SavedLocation) {
        locations.removeAll { $0.id == location.id }
        SavedLocationsStorage.save(locations)
    }

    /// Reorders the saved list. Saved order *is* pager order — `pages` derives
    /// from it — so dragging a card here also changes where that location sits
    /// in the swipe deck, which is the point.
    ///
    /// Offsets index into the unlocked prefix, which is the only part the list
    /// shows. Dormant over-cap entries stay pinned behind it rather than being
    /// shuffled around by a drag the user can't see the far end of.
    @MainActor
    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        var unlocked = Array(locations.prefix(visibleCount))
        let dormant = Array(locations.dropFirst(visibleCount))
        unlocked.move(fromOffsets: source, toOffset: destination)
        locations = unlocked + dormant
        SavedLocationsStorage.save(locations)
    }

    /// Split point between what the list renders and what's dormant. Read
    /// once per mutation so a tier change mid-drag can't desync the halves.
    @MainActor
    private var visibleCount: Int {
        min(locations.count, PremiumGate.maxSavedLocations)
    }

    /// Sets a user-chosen label. Passing nil, or anything blank, clears the
    /// override and falls back to the name the API supplied.
    func rename(_ location: SavedLocation, to newName: String?) {
        guard let index = locations.firstIndex(where: { $0.id == location.id }) else { return }
        let trimmed = newName?.trimmingCharacters(in: .whitespacesAndNewlines)
        locations[index].customName = (trimmed?.isEmpty ?? true) ? nil : trimmed
        SavedLocationsStorage.save(locations)
    }
}
