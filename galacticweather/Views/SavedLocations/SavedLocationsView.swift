import SwiftUI

/// Sheet listing the user's saved locations (premium-only — see
/// `PremiumGate.canUseSavedLocations`). Lets them bookmark the location
/// currently on screen, jump back to any saved spot, and remove entries.
struct SavedLocationsView: View {
    @Bindable var viewModel: SavedLocationsViewModel
    var weatherViewModel: WeatherViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var isPaywallOpen = false

    private var backgroundColor: Color { Color(hex: "#0a0e16") }
    private var textColor: Color { Color(hex: "#f2f5fa") }
    private var accentColor: Color { Color(hex: "#8fc7ff") }

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    if PremiumGate.canUseSavedLocations {
                        saveCurrentRow
                        list
                    } else {
                        upsell
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .foregroundStyle(textColor)
        .sheet(isPresented: $isPaywallOpen) {
            PaywallView(context: .savedLocations)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("SAVED LOCATIONS")
                    .font(.system(size: 12, weight: .medium))
                    .tracking(1.8)
                    .foregroundStyle(.white.opacity(0.6))
                Text("Your favorite destinations")
                    .font(.custom("PoiretOne-Regular", size: 30))
                    .tracking(0.5)
            }
            Spacer()
            Button("Close") { dismiss() }
                .font(.system(size: 13, weight: .semibold))
                .tracking(1)
                .textCase(.uppercase)
                .foregroundStyle(textColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(Capsule().fill(.white.opacity(0.1)))
                .overlay(Capsule().strokeBorder(.white.opacity(0.2)))
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var saveCurrentRow: some View {
        if let landed = weatherViewModel.landedLocation {
            let isSaved = viewModel.isSaved(lat: landed.lat, lon: landed.lon)
            let atCap = !isSaved && !viewModel.canSaveMore

            Button {
                viewModel.toggleSaved(displayName: landed.displayName, lat: landed.lat, lon: landed.lon)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                        .foregroundStyle(accentColor)
                    Text(isSaved ? "Saved \(landed.displayName)" : "Save \(landed.displayName)")
                        .font(.system(size: 15, weight: .medium))
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.white.opacity(0.08)))
            }
            .buttonStyle(.plain)
            .disabled(atCap)
            .opacity(atCap ? 0.5 : 1)

            if atCap {
                Text("You've saved the max of \(PremiumGate.maxSavedLocations) — remove one to add another.")
                    .font(.system(size: 12))
                    .foregroundStyle(textColor.opacity(0.55))
            }
        }
    }

    @ViewBuilder
    private var list: some View {
        if viewModel.locations.isEmpty {
            Text("No saved locations yet. Save the one you're viewing to keep it a tap away.")
                .font(.system(size: 13))
                .foregroundStyle(textColor.opacity(0.6))
        } else {
            VStack(spacing: 6) {
                ForEach(viewModel.locations) { location in
                    locationRow(location)
                }
            }
        }
    }

    private func locationRow(_ location: SavedLocation) -> some View {
        HStack(spacing: 14) {
            Button {
                Task { await weatherViewModel.goToLocation(lat: location.lat, lon: location.lon) }
                dismiss()
            } label: {
                Text(location.displayName)
                    .font(.system(size: 15))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Button {
                viewModel.remove(location)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(textColor.opacity(0.4))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.white.opacity(0.05)))
    }

    private var upsell: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Save your favorite locations and jump back with one tap. Premium unlocks up to \(PremiumGate.maxSavedLocations), synced across your devices.")
                .font(.system(size: 14))
                .foregroundStyle(textColor.opacity(0.75))

            Button("Unlock Premium") { isPaywallOpen = true }
                .font(.system(size: 15, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(accentColor)
                .foregroundStyle(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
