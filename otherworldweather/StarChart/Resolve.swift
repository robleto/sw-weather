import Foundation

/// Stable FNV-1a hash of a string -> non-negative value. Used to pick which
/// world a multi-assigned slot shows, so the choice is steady within a day
/// but differs between days and between slots. Port of the web app's
/// `src/lib/starchart/resolve.ts` (`hash`).
private func fnv1aHash(_ value: String) -> UInt32 {
    var hash: UInt32 = 2_166_136_261
    for byte in value.utf8 {
        hash ^= UInt32(byte)
        hash = hash &* 16_777_619
    }
    return hash
}

/// Local calendar day, so rotation flips at the user's midnight, not UTC's.
private func dayKey(_ now: Date, calendar: Calendar = .current) -> String {
    let components = calendar.dateComponents([.year, .month, .day], from: now)
    return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
}

/// Pick which world a slot shows right now.
///
/// A slot with several assigned worlds rotates daily rather than picking at
/// random on every render — re-rendering must not swap the background out
/// from under someone mid-session.
func pickWorldForSlot(_ slotId: SlotId, assigned: [WorldId], now: Date = Date()) -> WorldId {
    guard assigned.count > 1 else { return assigned.first ?? "" }
    let index = Int(fnv1aHash("\(dayKey(now)):\(slotId)") % UInt32(assigned.count))
    return assigned[index]
}

/// Resolve a weather slot to the world that should be displayed, honoring any
/// user customization. Falls back to the slot default, then to the temperate
/// clear-sky slot, so this never fails to resolve a slot the app can land in.
func resolveWorld(slotId: SlotId, overrides: StarChartOverrides = [:], now: Date = Date()) -> ResolvedWorld {
    guard let slot = getSlot(slotId) ?? getSlot(FALLBACK_SLOT_ID) else {
        return .idle
    }

    let assigned = overrides[slot.id] ?? []
    let customized = !assigned.isEmpty

    let worldId = customized ? pickWorldForSlot(slot.id, assigned: assigned, now: now) : slot.defaultWorld

    // A stored world that no longer exists shouldn't blank the screen.
    guard let world = getWorld(worldId) ?? getWorld(slot.defaultWorld) else {
        return ResolvedWorld(
            slotId: slot.id,
            planet: "default",
            planetName: "",
            description: "",
            color: WorldColor(primary: "#000000", headline: "#000000"),
            customized: false
        )
    }

    let usingDefault = !customized && world.id == slot.defaultWorld

    return ResolvedWorld(
        slotId: slot.id,
        planet: world.id,
        planetName: world.name,
        // Slot-specific copy only applies while the slot is untouched.
        description: (usingDefault ? slot.defaultDescription : nil) ?? world.description,
        color: world.color,
        customized: customized
    )
}
