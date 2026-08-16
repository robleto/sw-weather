import Foundation

/// Port of the TypeScript lat/lon-detecting location query parser and its
/// associated normalization helpers.
enum LocationQueryParser {
    /// Trims the string, then collapses any run of whitespace characters into a single space.
    static func normalizeWhitespace(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        let components = trimmed.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        return components.joined(separator: " ")
    }

    /// Removes any whitespace immediately before or after a comma, then trims.
    static func normalizeCommaSpacing(_ value: String) -> String {
        // Manual scan: strip whitespace runs immediately adjacent to commas.
        let chars = Array(value)
        var i = 0
        var output: [Character] = []
        while i < chars.count {
            let c = chars[i]
            if c == "," {
                // Remove trailing whitespace already appended before the comma.
                while let last = output.last, last.isWhitespace {
                    output.removeLast()
                }
                output.append(",")
                // Skip whitespace after the comma.
                i += 1
                while i < chars.count, chars[i].isWhitespace {
                    i += 1
                }
                continue
            }
            output.append(c)
            i += 1
        }
        return String(output).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// normalizeCommaSpacing(normalizeWhitespace(value)), lowercased.
    static func normalizeLocationQuery(_ value: String) -> String {
        normalizeCommaSpacing(normalizeWhitespace(value)).lowercased()
    }

    private static let coordinatePattern = "^\\s*(-?\\d+(?:\\.\\d+)?)\\s*,\\s*(-?\\d+(?:\\.\\d+)?)\\s*$"

    private static let coordinateRegex: NSRegularExpression = {
        // The pattern is a fixed, known-valid literal, so force-try is safe here.
        // swiftlint:disable:next force_try
        try! NSRegularExpression(pattern: coordinatePattern)
    }()

    /// Parses a raw, user-entered location query into a `ParsedLocationQuery`.
    static func parseLocationQuery(_ rawQuery: String) -> ParsedLocationQuery {
        let trimmed = normalizeWhitespace(rawQuery)
        guard !trimmed.isEmpty else { return .empty }

        let fullRange = NSRange(trimmed.startIndex..<trimmed.endIndex, in: trimmed)
        if let match = coordinateRegex.firstMatch(in: trimmed, range: fullRange),
           match.range == fullRange,
           let latRange = Range(match.range(at: 1), in: trimmed),
           let lonRange = Range(match.range(at: 2), in: trimmed) {
            let latString = String(trimmed[latRange])
            let lonString = String(trimmed[lonRange])
            if let lat = Double(latString), let lon = Double(lonString),
               lat.isFinite, lon.isFinite,
               (-90...90).contains(lat), (-180...180).contains(lon) {
                return .coordinates(lat: lat, lon: lon, normalizedQuery: normalizeLocationQuery(trimmed))
            }
        }

        return .geocode(query: normalizeCommaSpacing(trimmed), normalizedQuery: normalizeLocationQuery(trimmed))
    }
}
