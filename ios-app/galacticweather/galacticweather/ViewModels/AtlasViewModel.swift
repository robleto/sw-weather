import Foundation
import Observation

/// Owns the user's Atlas (their slot -> world assignments) and its
/// persistence. Port of the web app's `src/app/hooks/useAtlas.ts`. The
/// first read is still synchronous (no hydration-race like the web app's
/// `localStorage` effect), but the assignments can now change underneath the
/// app when another device edits them via iCloud — the remote-change
/// observer below handles that.
@Observable
final class AtlasViewModel {
    private(set) var overrides: AtlasOverrides

    @ObservationIgnored private var remoteChangeObserver: NSObjectProtocol?

    init() {
        overrides = AtlasStorage.load()
        AtlasStorage.startSync()
        remoteChangeObserver = AtlasStorage.observeRemoteChanges { [weak self] merged in
            self?.overrides = merged
        }
    }

    deinit {
        if let remoteChangeObserver {
            NotificationCenter.default.removeObserver(remoteChangeObserver)
        }
    }

    var customizedCount: Int { overrides.count }

    @MainActor var canAssignMultipleWorlds: Bool { PremiumGate.canAssignMultipleWorlds }

    /// Replace a slot's assignment. An empty list restores the default. Every
    /// slot is freely editable; locked (premium) worlds are silently dropped
    /// rather than trusted from the caller — the picker UI should never let
    /// one through, but this keeps the guarantee here too.
    @MainActor func assignSlot(_ slotId: SlotId, worldIds: [WorldId]) {
        let allowed = worldIds.filter { id in getWorld(id).map(PremiumGate.canUseWorld) ?? false }
        let unique = orderedUnique(allowed)
        if unique.isEmpty {
            overrides.removeValue(forKey: slotId)
        } else {
            overrides[slotId] = unique
        }
        AtlasStorage.save(overrides)
    }

    /// The single-assign path: replaces the slot's entire assignment with one
    /// world rather than appending to it.
    @MainActor func assignSingleWorld(slotId: SlotId, worldId: WorldId) {
        guard let world = getWorld(worldId), PremiumGate.canUseWorld(world) else { return }
        overrides[slotId] = [worldId]
        AtlasStorage.save(overrides)

        Analytics.track(
            AnalyticsSignal.atlasWorldAssigned,
            AnalyticsPayload.atlasWorldAssigned(slotId: slotId, action: .assign)
        )
    }

    /// Add or remove a single world from a slot, for multi-assign.
    @MainActor func toggleWorld(slotId: SlotId, worldId: WorldId) {
        guard let world = getWorld(worldId), PremiumGate.canUseWorld(world) else { return }
        let existing = overrides[slotId] ?? []
        guard canAssignMultipleWorlds || existing.isEmpty || existing.contains(worldId) else { return }

        var assigned = existing
        if let index = assigned.firstIndex(of: worldId) {
            assigned.remove(at: index)
        } else {
            assigned.append(worldId)
        }

        if assigned.isEmpty {
            overrides.removeValue(forKey: slotId)
        } else {
            overrides[slotId] = assigned
        }
        AtlasStorage.save(overrides)

        // Read from `existing`, before the mutation above, so the signal says
        // which direction the toggle went.
        Analytics.track(
            AnalyticsSignal.atlasWorldAssigned,
            AnalyticsPayload.atlasWorldAssigned(
                slotId: slotId,
                action: existing.contains(worldId) ? .unassign : .assign
            )
        )
    }

    func resetSlot(_ slotId: SlotId) {
        overrides.removeValue(forKey: slotId)
        AtlasStorage.save(overrides)
    }

    func resetAll() {
        overrides = [:]
        AtlasStorage.clear()
    }
}
