enum Grapheme17 {
    static func boundaries(_ text: String) -> [Int] {
        var scalars = text.unicodeScalars.makeIterator()
        guard let first = scalars.next() else { return [0] }

        var result = [0]
        var cursor = first.value > 0xFFFF ? 2 : 1
        var categoryBefore = Grapheme17Data.category(first.value)
        var state = nextState(1, category: categoryBefore, codePoint: first.value)

        while let scalar = scalars.next() {
            let categoryAfter = Grapheme17Data.category(scalar.value)
            let pairMask = Grapheme17Data.pairMasks[(categoryBefore << 4) | categoryAfter]
            if state & pairMask == 0 { result.append(cursor) }
            state = nextState(state, category: categoryAfter, codePoint: scalar.value)
            cursor += scalar.value > 0xFFFF ? 2 : 1
            categoryBefore = categoryAfter
        }
        result.append(text.utf16.count)
        return result
    }

    private static func nextState(_ state: Int, category: Int, codePoint: UInt32) -> Int {
        switch category {
        case 3:
            return state & 32 != 0 ? nextExtend(state, codePoint: codePoint) : state & 21
        case 4:
            return 17
        case 10:
            return (state & 2) ^ 3
        case 14:
            return ((state & 16) >> 2) | (state & 41)
        case 15:
            return 33
        default:
            return 1
        }
    }

    private static func nextExtend(_ state: Int, codePoint: UInt32) -> Int {
        if codePoint == 0x200C { return state & 21 }
        if state & 8 != 0 || Grapheme17Data.isLinker(codePoint) {
            return (state & 21) | 40
        }
        return (state & 21) | 32
    }
}
