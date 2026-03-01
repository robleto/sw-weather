# Changelog

All notable changes to this project are documented in this file.

## 0.2.0 - 2026-03-01

### Added

- Ambiguous location resolution with robust parsing for:
  - `City`
  - `City, ST`
  - `City, CountryCode`
  - `ZIP/Postal`
  - `lat,lon`
- Candidate disambiguation dropdown UI under the search input.
- Server-side geocoding endpoint: `/api/geocode`.
- 24-hour client-side geocode caching in localStorage.
- Sitemap generation at `/sitemap.xml`.

### Changed

- Search now resolves to explicit `lat/lon` before weather fetch.
- Weather and geocode API keys are now server-only (`OPENWEATHERMAP_API_KEY`).
- Improved page-level loading and error states for geolocation/location resolution.
- Enhanced accessibility in location search (combobox/listbox semantics + keyboard navigation).
- Expanded SEO metadata (canonical/Open Graph/Twitter metadata).
- Updated weather description copy for consistency and readability.

### Fixed

- Resolved ambiguous city lookups (e.g., `Paris`) by letting users pick specific candidates.
- Removed dead component/style drift from old header search.
- Replaced `<img>` with `next/image` in weather layers and footer icons.
- Corrected `clear_scorching` key typo and aligned lookups.
- Hardened fallback weather mapping so unknown conditions always map to a valid planet theme.

### Security

- Removed client-side direct geocoding requests with exposed public API key usage.
- Hardened `/api/weather` with coordinate validation and safer upstream error handling.

### Maintenance

- Removed unused dependencies (`axios`, `lodash.debounce`, `cors`, related types).
- Added `.history/` to `.gitignore` to prevent workspace drift noise.
- Refreshed Browserslist data.
