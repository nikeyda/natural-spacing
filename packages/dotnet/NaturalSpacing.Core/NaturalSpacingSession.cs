namespace NaturalSpacing.Core;

public sealed class NaturalSpacingSession
{
    private List<SuppressedBoundary> _suppressions = [];
    private FieldPolicy? _lastPolicy;

    public int SuppressedBoundaryCount => _suppressions.Count;

    public void Reset()
    {
        _suppressions.Clear();
        _lastPolicy = null;
    }

    public EditPlan Process(EditSnapshot snapshot)
    {
        if (_lastPolicy is not null && _lastPolicy != snapshot.Policy) _suppressions.Clear();
        _lastPolicy = snapshot.Policy;
        Rebase(snapshot);
        if (snapshot.Policy == FieldPolicy.NaturalLanguage && snapshot.ComposingRange is null &&
            DeletedBoundary(snapshot) is { } boundary)
        {
            _suppressions.RemoveAll(item => item.Offset == boundary.Offset);
            _suppressions.Add(boundary);
        }

        var planned = NaturalSpacingFormatter.PlanEdit(snapshot, _suppressions.Select(item => item.Offset).ToHashSet());
        var plan = planned.Decision == PlanDecision.NoChange && _suppressions.Count > 0
            ? planned with { Decision = PlanDecision.Suppressed }
            : planned;
        _suppressions = _suppressions.Select(suppression =>
        {
            var mapped = NaturalSpacingFormatter.MapSelection(
                new TextSelection(suppression.Offset, suppression.Offset), plan.Insertions).Anchor;
            var context = BoundaryContext(plan.ResultText, mapped);
            return context is not null && context.Left == suppression.Left && context.Right == suppression.Right
                ? suppression with { Offset = mapped }
                : null;
        }).Where(item => item is not null).Select(item => item!).ToList();
        return plan;
    }

    public ProposedEditResult ProcessProposedEdit(ProposedEdit edit) =>
        NaturalSpacingFormatter.ProcessProposedEdit(edit, Process);

    private void Rebase(EditSnapshot snapshot)
    {
        var start = snapshot.ChangedRange.Start;
        var end = start + snapshot.ChangedRange.Length;
        var delta = snapshot.AfterUserText.Length - snapshot.BeforeText.Length;
        _suppressions = _suppressions.Select(suppression =>
        {
            var offset = suppression.Offset;
            if (offset > end || (snapshot.ChangedRange.Length > 0 && offset == end)) offset += delta;
            else if (offset > start && offset < end) return null;
            var context = BoundaryContext(snapshot.AfterUserText, offset);
            return context is not null && context.Left == suppression.Left && context.Right == suppression.Right
                ? suppression with { Offset = offset }
                : null;
        }).Where(item => item is not null).Select(item => item!).ToList();
    }

    private static SuppressedBoundary? DeletedBoundary(EditSnapshot snapshot)
    {
        if (snapshot.EditKind != EditKind.Delete || snapshot.ChangedRange.Length != 1 ||
            snapshot.BeforeText.Length - 1 != snapshot.AfterUserText.Length ||
            snapshot.BeforeText.Substring(snapshot.ChangedRange.Start, 1) != " ") return null;
        var context = BoundaryContext(snapshot.AfterUserText, snapshot.ChangedRange.Start);
        return context is not null && NaturalSpacingFormatter.Reason(context.LeftCategory, context.RightCategory) is not null
            ? new SuppressedBoundary(snapshot.ChangedRange.Start, context.Left, context.Right)
            : null;
    }

    private static Boundary? BoundaryContext(string text, int offset)
    {
        var graphemes = NaturalSpacingFormatter.Segment(text);
        var rightIndex = -1;
        for (var index = 0; index < graphemes.Count; index++)
            if (graphemes[index].Start == offset) { rightIndex = index; break; }
        if (rightIndex <= 0) return null;
        var left = graphemes[rightIndex - 1];
        var right = graphemes[rightIndex];
        return left.End == offset ? new Boundary(left.Text, right.Text, left.Category, right.Category) : null;
    }

    private sealed record SuppressedBoundary(int Offset, string Left, string Right);
    private sealed record Boundary(string Left, string Right, Category LeftCategory, Category RightCategory);
}
