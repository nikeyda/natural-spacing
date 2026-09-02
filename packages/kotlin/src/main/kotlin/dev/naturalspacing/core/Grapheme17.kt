package dev.naturalspacing.core

internal object Grapheme17 {
    fun boundaries(text: String): IntArray {
        if (text.isEmpty()) return intArrayOf(0)

        val result = mutableListOf(0)
        var codePoint = text.codePointAt(0)
        var cursor = Character.charCount(codePoint)
        var categoryBefore = Grapheme17Data.category(codePoint)
        var state = nextState(1, categoryBefore, codePoint)

        while (cursor < text.length) {
            codePoint = text.codePointAt(cursor)
            val categoryAfter = Grapheme17Data.category(codePoint)
            val pairMask = Grapheme17Data.pairMasks[(categoryBefore shl 4) or categoryAfter]
            if (state and pairMask == 0) result += cursor
            state = nextState(state, categoryAfter, codePoint)
            cursor += Character.charCount(codePoint)
            categoryBefore = categoryAfter
        }
        result += text.length
        return result.toIntArray()
    }

    private fun nextState(state: Int, category: Int, codePoint: Int): Int = when (category) {
        3 -> if (state and 32 != 0) nextExtend(state, codePoint) else state and 21
        4 -> 17
        10 -> (state and 2) xor 3
        14 -> ((state and 16) shr 2) or (state and 41)
        15 -> 33
        else -> 1
    }

    private fun nextExtend(state: Int, codePoint: Int): Int {
        if (codePoint == 0x200c) return state and 21
        if (state and 8 != 0 || Grapheme17Data.isLinker(codePoint)) {
            return (state and 21) or 40
        }
        return (state and 21) or 32
    }
}
