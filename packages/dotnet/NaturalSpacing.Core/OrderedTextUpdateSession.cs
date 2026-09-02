namespace NaturalSpacing.Core;

/// <summary>
/// Coordinates complete hypotheses from revision-capable ASR or dictation
/// providers while retaining only the active utterance ID and revision.
/// </summary>
public sealed class OrderedTextUpdateSession(
    FieldPolicy policy = FieldPolicy.NaturalLanguage,
    OrderedTextSource source = OrderedTextSource.Asr)
{
    private string? _activeUtteranceId;
    private long _lastRevision = -1;

    public FieldPolicy Policy { get; } = policy;
    public OrderedTextSource Source { get; } = source;

    public bool Start(string utteranceId)
    {
        ArgumentNullException.ThrowIfNull(utteranceId);
        if (utteranceId.Length == 0) return false;
        _activeUtteranceId = utteranceId;
        _lastRevision = -1;
        return true;
    }

    public OrderedTextUpdateResult Accept(OrderedTextUpdateEvent update)
    {
        ArgumentNullException.ThrowIfNull(update);
        if (update.Revision < 0) return Rejected(OrderedTextUpdateReason.InvalidRevision);
        if (_activeUtteranceId != update.UtteranceId)
            return Rejected(OrderedTextUpdateReason.InactiveUtterance);
        if (update.Revision <= _lastRevision)
            return Rejected(OrderedTextUpdateReason.StaleRevision);

        _lastRevision = update.Revision;
        var output = NaturalSpacingPolicy.Format(new TextUpdate(
            update.Text,
            Policy,
            Source == OrderedTextSource.Asr ? TextSource.Asr : TextSource.Dictation,
            update.Stability));
        if (update.Stability == TextStability.Final)
        {
            _activeUtteranceId = null;
            _lastRevision = -1;
        }
        return new OrderedTextUpdateResult(true, OrderedTextUpdateReason.Accepted, output);
    }

    public bool Cancel(string utteranceId)
    {
        ArgumentNullException.ThrowIfNull(utteranceId);
        if (_activeUtteranceId != utteranceId) return false;
        _activeUtteranceId = null;
        _lastRevision = -1;
        return true;
    }

    private static OrderedTextUpdateResult Rejected(OrderedTextUpdateReason reason) =>
        new(false, reason, null);
}
