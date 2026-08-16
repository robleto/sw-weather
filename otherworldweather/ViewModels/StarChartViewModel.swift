import Foundation
import Observation

/// Owns the user's Star Chart (their slot -> world assignments) and its
/// persistence. Port of the web app's `src/app/hooks/useStarChart.ts`. The
/// first read is still synchronous (no hydration-race like the web app's
/// `localStorage` effect), but the chart can now change underneath the app
/// when another device edits it via iCloud — the remote-change observer
/// below handles that.
@Observable
final class StarChartViewModel {
    private(set) var overrides: StarChartOverrides

    @ObservationIgnored private var remoteChangeObserver: NSObjectProtocol?

    init() {
        overrides = StarChartStorage.load()
        StarChartStorage.startSync()
        remoteChangeObserver = StarChartStorage.observeRemoteChanges { [weak self] merged in
            self?.overrides = merged
        }
    }

    deinit {
        if let remoteChangeObserver {
            NotificationCenter.default.removeObserver(remoteChangeObserver)
        }
    }

    var customizedCount: Int { overrides.count }

    @MainActor func canEdit(_ slotId: SlotId) -> Bool {
        PremiumGate.canEditSlot(slotId, overrides: overrides)
    }

    @MainActor var canAssignMultipleWorlds: Bool { PremiumGate.canAssignMultipleWorlds }

    /// Replace a slot's assignment. An empty list restores the default.
    @MainActor func assignSlot(_ slotId: SlotId, worldIds: [WorldId]) {
        guard canEdit(slotId) else { return }
        let unique = orderedUnique(worldIds)
        if unique.isEmpty {
            overrides.removeValue(forKey: slotId)
        } else {
            overrides[slotId] = unique
        }
        StarChartStorage.save(overrides)
    }

    /// The free-tier assignment path: replaces the slot's entire assignment
    /// with a single world rather than appending to it.
    @MainActor func assignSingleWorld(slotId: SlotId, worldId: WorldId) {
        guard canEdit(slotId) else { return }
        overrides[slotId] = [worldId]
        StarChartStorage.save(overrides)
    }

    /// Add or remove a single world from a slot, for multi-assign.
    @MainActor func toggleWorld(slotId: SlotId, worldId: WorldId) {
        guard canEdit(slotId) else { return }
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
        StarChartStorage.save(overrides)
    }

    func resetSlot(_ slotId: SlotId) {
        overrides.removeValue(forKey: slotId)
        StarChartStorage.save(overrides)
    }

    func resetAll() {
        overrides = [:]
        StarChartStorage.clear()
    }
}
