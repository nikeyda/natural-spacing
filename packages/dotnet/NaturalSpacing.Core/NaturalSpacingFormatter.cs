using System.Text;

namespace NaturalSpacing.Core;

public static class NaturalSpacingFormatter
{
    public const string UnicodeVersion = "17.0.0";

    public static string Normalize(string text, FieldPolicy policy = FieldPolicy.Verbatim) =>
        policy == FieldPolicy.NaturalLanguage ? Apply(EligibleInsertions(text), text) : text;

    public static EditPlan PlanEdit(EditSnapshot snapshot) => PlanEdit(snapshot, new HashSet<int>());

    internal static EditPlan PlanEdit(EditSnapshot snapshot, IReadOnlySet<int> suppressedOffsets)
    {
        if (snapshot.Policy == FieldPolicy.Verbatim) return Unchanged(snapshot, PlanDecision.Verbatim);
        if (snapshot.ComposingRange is not null) return Unchanged(snapshot, PlanDecision.Composing);

        var replacementLength = snapshot.AfterUserText.Length -
            (snapshot.BeforeText.Length - snapshot.ChangedRange.Length);
        var start = snapshot.ChangedRange.Start;
        var end = start + replacementLength;
        var eligible = EligibleInsertions(snapshot.AfterUserText)
            .Where(item => item.Offset >= start && item.Offset <= end).ToArray();
        var insertions = eligible.Where(item => !suppressedOffsets.Contains(item.Offset)).ToArray();
        if (insertions.Length == 0)
        {
            return Unchanged(snapshot, eligible.Length == 0 ? PlanDecision.NoChange : PlanDecision.Suppressed);
        }

        var result = Apply(insertions, snapshot.AfterUserText);
        if (snapshot.MaxLengthUtf16 is int limit && result.Length > limit)
            return Unchanged(snapshot, PlanDecision.LengthLimited);
        return new EditPlan(PlanDecision.Applied, insertions, result, MapSelection(snapshot.Selection, insertions));
    }

    public static ProposedEditResult PlanProposedEdit(ProposedEdit edit) =>
        ProcessProposedEdit(edit, PlanEdit);

    public static ProposedEdit? ReplacingDifference(
        string beforeText,
        string afterText,
        FieldPolicy policy,
        TextSelection? selectionAfterEdit = null,
        int? maxLengthUtf16 = null)
    {
        var prefix = 0;
        while (prefix < beforeText.Length && prefix < afterText.Length && beforeText[prefix] == afterText[prefix]) prefix++;
        var suffix = 0;
        while (suffix < beforeText.Length - prefix && suffix < afterText.Length - prefix &&
               beforeText[^(suffix + 1)] == afterText[^(suffix + 1)]) suffix++;
        var oldLength = beforeText.Length - prefix - suffix;
        var newLength = afterText.Length - prefix - suffix;
        if (oldLength == 0 && newLength == 0) return null;
        var replacement = afterText.Substring(prefix, newLength);
        var kind = replacement.Length == 0 && oldLength > 0 ? EditKind.Delete :
            oldLength == 0 ? EditKind.Insert : EditKind.Replace;
        return new ProposedEdit(beforeText, new TextRange(prefix, oldLength), replacement, kind, policy,
            SelectionAfterEdit: selectionAfterEdit, MaxLengthUtf16: maxLengthUtf16);
    }

    internal static ProposedEditResult ProcessProposedEdit(
        ProposedEdit edit,
        Func<EditSnapshot, EditPlan> planner)
    {
        ArgumentOutOfRangeException.ThrowIfNegative(edit.Range.Start);
        ArgumentOutOfRangeException.ThrowIfNegative(edit.Range.Length);
        if (edit.Range.Start > edit.Text.Length - edit.Range.Length)
            throw new ArgumentOutOfRangeException(nameof(edit));
        var after = edit.Text[..edit.Range.Start] + edit.ReplacementText +
            edit.Text[(edit.Range.Start + edit.Range.Length)..];
        var caret = edit.Range.Start + edit.ReplacementText.Length;
        var plan = planner(new EditSnapshot(edit.Text, after, edit.Range,
            edit.SelectionAfterEdit ?? new TextSelection(caret, caret), edit.ComposingRange,
            edit.EditKind, edit.Policy, edit.MaxLengthUtf16));
        if (plan.Decision != PlanDecision.Applied)
            return new ProposedEditResult(plan, edit.ReplacementText, false);
        var relative = plan.Insertions.Select(item => new Insertion(item.Offset - edit.Range.Start, item.Reason)).ToArray();
        return new ProposedEditResult(plan, Apply(relative, edit.ReplacementText), true);
    }

    internal static IReadOnlyList<Insertion> EligibleInsertions(string text)
    {
        var graphemes = Segment(text);
        var result = new List<Insertion>();
        for (var index = 1; index < graphemes.Count; index++)
        {
            if (Reason(graphemes[index - 1].Category, graphemes[index].Category) is { } reason)
                result.Add(new Insertion(graphemes[index].Start, reason));
        }
        return result;
    }

    internal static TextSelection MapSelection(TextSelection selection, IReadOnlyList<Insertion> insertions)
    {
        int Map(int value) => value + insertions.Sum(item => value >= item.Offset ? item.Text.Length : 0);
        return new TextSelection(Map(selection.Anchor), Map(selection.Focus));
    }

    internal static string Apply(IReadOnlyList<Insertion> insertions, string text)
    {
        var result = new StringBuilder(text);
        for (var index = insertions.Count - 1; index >= 0; index--)
            result.Insert(insertions[index].Offset, insertions[index].Text);
        return result.ToString();
    }

    internal static InsertionReason? Reason(Category left, Category right) =>
        (left, right) switch
        {
            (Category.Han, Category.Latin) or (Category.Latin, Category.Han) => InsertionReason.HanLatin,
            (Category.Han, Category.AsciiDigit) or (Category.AsciiDigit, Category.Han) => InsertionReason.HanAsciiDigit,
            _ => null,
        };

    internal static IReadOnlyList<Grapheme> Segment(string text)
    {
        var result = new List<Grapheme>();
        var boundaries = Grapheme17.Boundaries(text);
        for (var index = 1; index < boundaries.Count; index++)
        {
            var start = boundaries[index - 1];
            var end = boundaries[index];
            var value = text[start..end];
            result.Add(new Grapheme(value, start, end, Classify(value)));
        }
        return result;
    }

    private static Category Classify(string value)
    {
        var runes = value.EnumerateRunes().ToArray();
        if (runes.Any(rune => Unicode17.Contains(Unicode17.WhiteSpaceRanges, rune.Value)))
            return Category.Whitespace;
        if (runes.Length == 1 && runes[0].Value is >= '0' and <= '9') return Category.AsciiDigit;
        var baseRune = runes.FirstOrDefault(rune => !Unicode17.Contains(Unicode17.MarkRanges, rune.Value));
        if (baseRune.Value == 0) return Category.Other;
        if (Unicode17.Contains(Unicode17.HanRanges, baseRune.Value)) return Category.Han;
        if (Unicode17.Contains(Unicode17.LatinRanges, baseRune.Value)) return Category.Latin;
        return Category.Other;
    }

    private static EditPlan Unchanged(EditSnapshot snapshot, PlanDecision decision) =>
        new(decision, [], snapshot.AfterUserText, snapshot.Selection);
}

internal enum Category { Han, Latin, AsciiDigit, Whitespace, Other }
internal readonly record struct Grapheme(string Text, int Start, int End, Category Category);
