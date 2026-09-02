namespace NaturalSpacing.Core;

/// <summary>
/// Coordinates controls that report a settled text value after a native edit.
/// Keep one instance per field and do not reconcile while composition is active.
/// </summary>
public sealed class NaturalSpacingObservedTextSession
{
    private readonly NaturalSpacingSession _session = new();

    public NaturalSpacingObservedTextSession(string initialText = "")
    {
        ArgumentNullException.ThrowIfNull(initialText);
        SettledText = initialText;
    }

    public string SettledText { get; private set; }

    /// <summary>
    /// Resets deletion intent and adopts a host-controlled value as the new baseline.
    /// </summary>
    public void Sync(string text)
    {
        ArgumentNullException.ThrowIfNull(text);
        _session.Reset();
        SettledText = text;
    }

    /// <summary>
    /// Reconciles one observed native edit. A null result means there is no settled
    /// change to apply, including while composition remains active.
    /// </summary>
    public ProposedEditResult? Reconcile(
        string currentText,
        FieldPolicy policy,
        TextSelection? selection = null,
        int? maxLengthUtf16 = null,
        bool isComposing = false)
    {
        ArgumentNullException.ThrowIfNull(currentText);
        if (isComposing || currentText == SettledText) return null;

        var proposed = NaturalSpacingFormatter.ReplacingDifference(
            SettledText,
            currentText,
            policy,
            selection ?? new TextSelection(currentText.Length, currentText.Length),
            maxLengthUtf16);
        if (proposed is null)
        {
            SettledText = currentText;
            return null;
        }

        var result = _session.ProcessProposedEdit(proposed);
        SettledText = result.Plan.ResultText;
        return result;
    }
}
