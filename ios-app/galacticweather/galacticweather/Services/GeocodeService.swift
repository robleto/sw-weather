import Foundation

/// Errors thrown by `GeocodeService`.
enum GeocodeServiceError: Error, LocalizedError {
    /// `OPENWEATHERMAP_API_KEY` was missing (or empty) in Info.plist.
    case missingAPIKey
    /// The query could not be turned into a valid request URL.
    case invalidQuery
    /// The API returned a non-2xx status code.
    case httpError(statusCode: Int)
    /// The response body could not be decoded.
    case decodingFailed(underlying: Error)
    /// The query was empty (matches route.ts's `q is required` guard).
    case emptyQuery
    /// The query exceeded the original route's 120-character limit.
    case queryTooLong

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "The OpenWeatherMap API key is missing from the app configuration."
        case .invalidQuery:
            return "The location query could not be sent to the geocoding service."
        case .httpError(let statusCode):
            return "The geocoding service returned an error (status code \(statusCode))."
        case .decodingFailed:
            return "The geocoding service returned data that could not be understood."
        case .emptyQuery:
            return "q is required"
        case .queryTooLong:
            return "q is too long"
        }
    }
}

/// Calls the OpenWeatherMap direct geocoding endpoint from the device, then
/// normalizes and dedupes the raw results the same way the original Next.js
/// `/api/geocode` route did.
struct GeocodeService {
    /// Raw shape returned by OpenWeatherMap's geocoding API.
    private struct RawCandidate: Decodable {
        let name: String
        let lat: Double
        let lon: Double
        let state: String?
        let country: String?
    }

    private static let endpoint = URL(string: "https://api.openweathermap.org/geo/1.0/direct")!
    private static let candidateLimit = 5
    private static let apiKeyInfoDictionaryKey = "OPENWEATHERMAP_API_KEY"

    /// Geocodes a free-text query into a deduplicated list of location candidates.
    func geocode(query: String) async throws -> [LocationCandidate] {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: Self.apiKeyInfoDictionaryKey) as? String,
              !apiKey.isEmpty else {
            throw GeocodeServiceError.missingAPIKey
        }

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            throw GeocodeServiceError.emptyQuery
        }
        guard trimmedQuery.count <= 120 else {
            throw GeocodeServiceError.queryTooLong
        }

        var components = URLComponents(url: Self.endpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "q", value: trimmedQuery),
            URLQueryItem(name: "limit", value: String(Self.candidateLimit)),
            URLQueryItem(name: "appid", value: apiKey)
        ]

        guard let url = components.url else {
            throw GeocodeServiceError.invalidQuery
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeocodeServiceError.httpError(statusCode: -1)
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw GeocodeServiceError.httpError(statusCode: httpResponse.statusCode)
        }

        let rawCandidates: [RawCandidate]
        do {
            rawCandidates = try JSONDecoder().decode([RawCandidate].self, from: data)
        } catch {
            throw GeocodeServiceError.decodingFailed(underlying: error)
        }

        let normalized = rawCandidates
            .map { raw -> LocationCandidate in
                LocationCandidate(
                    name: raw.name.trimmingCharacters(in: .whitespacesAndNewlines),
                    regionOrState: raw.state?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
                    country: raw.country?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
                    lat: raw.lat,
                    lon: raw.lon
                )
            }
            .filter { !$0.name.isEmpty }

        // The API's limit=5 already caps result count, so no re-truncation is needed here.
        return Self.dedupe(normalized)
    }

    /// Deduplicates candidates while preserving first-seen order, keyed by
    /// lowercased name/regionOrState/country plus lat/lon rounded to 4 decimal places.
    private static func dedupe(_ candidates: [LocationCandidate]) -> [LocationCandidate] {
        var seenKeys = Set<String>()
        var result: [LocationCandidate] = []

        for candidate in candidates {
            let key = [
                candidate.name.lowercased(),
                candidate.regionOrState.lowercased(),
                candidate.country.lowercased(),
                String(format: "%.4f", candidate.lat),
                String(format: "%.4f", candidate.lon)
            ].joined(separator: ":")

            if seenKeys.insert(key).inserted {
                result.append(candidate)
            }
        }

        return result
    }
}
