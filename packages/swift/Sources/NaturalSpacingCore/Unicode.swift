enum BoundaryCategory: Sendable {
    case han
    case latin
    case asciiDigit
    case whitespace
    case other
}

struct Grapheme: Sendable {
    let text: String
    let start: Int
    let end: Int
    let category: BoundaryCategory
}

extension NaturalSpacing {
    static func segment(_ text: String) -> [Grapheme] {
        let boundaries = Grapheme17.boundaries(text)
        let utf16 = text.utf16
        return zip(boundaries, boundaries.dropFirst()).map { start, end in
            let lowerUTF16 = utf16.index(utf16.startIndex, offsetBy: start)
            let upperUTF16 = utf16.index(utf16.startIndex, offsetBy: end)
            let lower = String.Index(lowerUTF16, within: text)!
            let upper = String.Index(upperUTF16, within: text)!
            let value = String(text[lower..<upper])
            return Grapheme(
                text: value,
                start: start,
                end: end,
                category: classify(value)
            )
        }
    }

    static func insertionReason(
        left: BoundaryCategory,
        right: BoundaryCategory
    ) -> InsertionReason? {
        if (left == .han && right == .latin) || (left == .latin && right == .han) {
            return .hanLatin
        }
        if (left == .han && right == .asciiDigit)
            || (left == .asciiDigit && right == .han)
        {
            return .hanAsciiDigit
        }
        return nil
    }

    private static func classify(_ grapheme: String) -> BoundaryCategory {
        let scalars = Array(grapheme.unicodeScalars)
        if scalars.contains(where: { Unicode17.contains(Unicode17.whiteSpaceRanges, $0.value) }) {
            return .whitespace
        }
        if scalars.count == 1, let scalar = scalars.first, (48...57).contains(scalar.value) {
            return .asciiDigit
        }
        guard let base = scalars.first(where: {
            !Unicode17.contains(Unicode17.markRanges, $0.value)
        }) else {
            return .other
        }
        if Unicode17.contains(Unicode17.hanRanges, base.value) {
            return .han
        }
        if Unicode17.contains(Unicode17.latinRanges, base.value) {
            return .latin
        }
        return .other
    }
}
