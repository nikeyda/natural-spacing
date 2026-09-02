using System.Text.RegularExpressions;

namespace NaturalSpacing.Core;

public static class NaturalSpacingPolicy
{
    private static readonly HashSet<ContentKind> NaturalKinds =
        [ContentKind.Prose, ContentKind.Title, ContentKind.Message, ContentKind.Note,
         ContentKind.Document, ContentKind.Transcript, ContentKind.AsrTranscript];
    private static readonly HashSet<ContentKind> VerbatimKinds =
        [ContentKind.Code, ContentKind.Identifier, ContentKind.Url, ContentKind.Email,
         ContentKind.Password, ContentKind.Token, ContentKind.FilePath, ContentKind.Command, ContentKind.Number];
    private static readonly Regex[] StructuredPatterns =
    [
        new(@"^(?:[a-z][a-z0-9+.-]*://|www\.)", RegexOptions.IgnoreCase),
        new(@"^[^\s@]+@[^\s@]+\.[^\s@]+$", RegexOptions.IgnoreCase),
        new(@"^(?:[A-Za-z]:[\\/]|~?[\\/])"),
        new(@"^(?:[A-Za-z_$][A-Za-z0-9_$-]*[.:/@\\])+[A-Za-z0-9_$.-]+$"),
        new(@"(?:=>|::|</?[A-Za-z][^>]*>|\{[^}]*}|`[^`]*`)"),
    ];

    public static PolicyRecommendation Recommend(PolicyContext? context = null)
    {
        context ??= new PolicyContext();
        if (context.IsSecure == true || context.ContentKind == ContentKind.Password)
            return Result(FieldPolicy.Verbatim, RecommendationConfidence.High, RecommendationSource.Safety, RecommendationReason.SecureContent, true);
        if (context.ExplicitPolicy is { } selectedPolicy)
            return Result(selectedPolicy, RecommendationConfidence.High, RecommendationSource.Explicit, RecommendationReason.ExplicitPolicy, true);
        var kind = context.ContentKind ?? ContentKind.Unknown;
        if (NaturalKinds.Contains(kind))
            return Result(FieldPolicy.NaturalLanguage, RecommendationConfidence.High, RecommendationSource.ContentKind, RecommendationReason.NaturalLanguageContent, true);
        if (VerbatimKinds.Contains(kind))
            return Result(FieldPolicy.Verbatim, RecommendationConfidence.High, RecommendationSource.ContentKind, RecommendationReason.StructuredContent, true);
        var value = context.Text?.Trim();
        if (!string.IsNullOrEmpty(value) && StructuredPatterns.Any(pattern => pattern.IsMatch(value)))
            return Result(FieldPolicy.Verbatim, RecommendationConfidence.Medium, RecommendationSource.TextHeuristic, RecommendationReason.StructuredText, false);
        if (kind == ContentKind.SearchQuery)
            return Result(FieldPolicy.NaturalLanguage, RecommendationConfidence.Medium, RecommendationSource.ContentKind, RecommendationReason.AmbiguousSearch, false);
        if (context.Text is not null && NaturalSpacingFormatter.EligibleInsertions(context.Text).Count > 0)
            return Result(FieldPolicy.NaturalLanguage, RecommendationConfidence.Medium, RecommendationSource.TextHeuristic, RecommendationReason.MixedNaturalLanguage, false);
        return Result(FieldPolicy.Verbatim, RecommendationConfidence.Low, RecommendationSource.Fallback, RecommendationReason.InsufficientEvidence, false);
    }

    public static FieldPolicy Resolve(
        PolicyContext? context = null,
        FieldPolicy fallback = FieldPolicy.Verbatim)
    {
        var recommended = Recommend(context);
        return recommended.AutoApply ? recommended.Policy : fallback;
    }

    public static FormattedTextUpdate Format(TextUpdate update)
    {
        var display = NaturalSpacingFormatter.Normalize(update.Text, update.Policy);
        return new FormattedTextUpdate(display, update.Stability == TextStability.Final ? display : null,
            display != update.Text, update.Policy, update.Source, update.Stability);
    }

    private static PolicyRecommendation Result(FieldPolicy policy, RecommendationConfidence confidence,
        RecommendationSource source, RecommendationReason reason, bool autoApply) =>
        new(policy, confidence, source, reason, autoApply);
}
