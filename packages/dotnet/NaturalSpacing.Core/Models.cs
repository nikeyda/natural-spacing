namespace NaturalSpacing.Core;

public enum FieldPolicy { NaturalLanguage, Verbatim }
public enum EditKind { Insert, Delete, Replace, Paste }
public enum PlanDecision { Applied, NoChange, Verbatim, Composing, Suppressed, LengthLimited }
public enum InsertionReason { HanLatin, HanAsciiDigit }

public readonly record struct TextRange(int Start, int Length);
public readonly record struct TextSelection(int Anchor, int Focus);
public readonly record struct Insertion(int Offset, InsertionReason Reason)
{
    public string Text => " ";
}

public sealed record EditSnapshot(
    string BeforeText,
    string AfterUserText,
    TextRange ChangedRange,
    TextSelection Selection,
    TextRange? ComposingRange,
    EditKind EditKind,
    FieldPolicy Policy,
    int? MaxLengthUtf16);

public sealed record EditPlan(
    PlanDecision Decision,
    IReadOnlyList<Insertion> Insertions,
    string ResultText,
    TextSelection Selection);

public sealed record ProposedEdit(
    string Text,
    TextRange Range,
    string ReplacementText,
    EditKind EditKind,
    FieldPolicy Policy,
    TextRange? ComposingRange = null,
    TextSelection? SelectionAfterEdit = null,
    int? MaxLengthUtf16 = null);

public sealed record ProposedEditResult(
    EditPlan Plan,
    string ReplacementText,
    bool RequiresReplacement);

public enum ContentKind
{
    Prose, Title, Message, Note, Document, Transcript, AsrTranscript,
    Code, Identifier, Url, Email, Password, Token, FilePath, Command,
    Number, SearchQuery, Unknown,
}

public enum RecommendationConfidence { High, Medium, Low }
public enum RecommendationSource { Explicit, Safety, ContentKind, TextHeuristic, Fallback }
public enum RecommendationReason
{
    ExplicitPolicy, SecureContent, NaturalLanguageContent, StructuredContent,
    AmbiguousSearch, StructuredText, MixedNaturalLanguage, InsufficientEvidence,
}

public sealed record PolicyContext(
    FieldPolicy? ExplicitPolicy = null,
    ContentKind? ContentKind = null,
    string? Text = null,
    bool? IsSecure = null);

public sealed record PolicyRecommendation(
    FieldPolicy Policy,
    RecommendationConfidence Confidence,
    RecommendationSource Source,
    RecommendationReason Reason,
    bool AutoApply);

public enum TextSource { Asr, Dictation, Imported, Generated }
public enum TextStability { Interim, Final }
public sealed record TextUpdate(string Text, FieldPolicy Policy, TextSource Source, TextStability Stability);
public sealed record FormattedTextUpdate(
    string DisplayText,
    string? CommittedText,
    bool Changed,
    FieldPolicy Policy,
    TextSource Source,
    TextStability Stability);

public enum OrderedTextSource { Asr, Dictation }
public enum OrderedTextUpdateReason { Accepted, InactiveUtterance, StaleRevision, InvalidRevision }

public sealed record OrderedTextUpdateEvent(
    string UtteranceId,
    long Revision,
    string Text,
    TextStability Stability);

public sealed record OrderedTextUpdateResult(
    bool Accepted,
    OrderedTextUpdateReason Reason,
    FormattedTextUpdate? Output);
