using System.Text;

namespace NaturalSpacing.Core;

internal static class Grapheme17
{
    internal static IReadOnlyList<int> Boundaries(string text)
    {
        if (text.Length == 0) return [0];

        var result = new List<int> { 0 };
        var first = Rune.GetRuneAt(text, 0);
        var cursor = first.Utf16SequenceLength;
        var categoryBefore = Grapheme17Data.Category(first.Value);
        var state = NextState(1, categoryBefore, first.Value);

        while (cursor < text.Length)
        {
            var rune = Rune.GetRuneAt(text, cursor);
            var categoryAfter = Grapheme17Data.Category(rune.Value);
            var pairMask = Grapheme17Data.PairMasks[(categoryBefore << 4) | categoryAfter];
            if ((state & pairMask) == 0) result.Add(cursor);
            state = NextState(state, categoryAfter, rune.Value);
            cursor += rune.Utf16SequenceLength;
            categoryBefore = categoryAfter;
        }
        result.Add(text.Length);
        return result;
    }

    private static int NextState(int state, int category, int codePoint) => category switch
    {
        3 => (state & 32) != 0 ? NextExtend(state, codePoint) : state & 21,
        4 => 17,
        10 => (state & 2) ^ 3,
        14 => ((state & 16) >> 2) | (state & 41),
        15 => 33,
        _ => 1,
    };

    private static int NextExtend(int state, int codePoint)
    {
        if (codePoint == 0x200C) return state & 21;
        return (state & 8) != 0 || Grapheme17Data.IsLinker(codePoint)
            ? (state & 21) | 40
            : (state & 21) | 32;
    }
}
