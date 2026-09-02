using NaturalSpacing.Core;

var context = new PolicyContext(ContentKind: ContentKind.Message);
var recommendation = NaturalSpacingPolicy.Recommend(context);
var policy = NaturalSpacingPolicy.Resolve(context);
var normalized = NaturalSpacingFormatter.Normalize("发布v2版本", policy);

if (!recommendation.AutoApply ||
    policy != FieldPolicy.NaturalLanguage ||
    normalized != "发布 v2 版本")
{
    throw new InvalidOperationException("Natural-language policy consumption failed.");
}

var advisory = new PolicyContext(
    ContentKind: ContentKind.SearchQuery,
    Text: "发布v2版本");
if (NaturalSpacingPolicy.Resolve(advisory) != FieldPolicy.Verbatim)
{
    throw new InvalidOperationException("Advisory policy must use the safe fallback.");
}

var secure = new PolicyContext(
    ExplicitPolicy: FieldPolicy.NaturalLanguage,
    ContentKind: ContentKind.Message,
    IsSecure: true);
if (NaturalSpacingPolicy.Resolve(secure) != FieldPolicy.Verbatim)
{
    throw new InvalidOperationException("Secure input must override natural-language policy.");
}

var observed = new NaturalSpacingObservedTextSession("中文");
var observedResult = observed.Reconcile(
    "中2文",
    FieldPolicy.NaturalLanguage,
    new TextSelection(2, 2));
if (observedResult is not { RequiresReplacement: true } ||
    observedResult.Plan.ResultText != "中 2 文" ||
    observedResult.Plan.Selection != new TextSelection(4, 4))
{
    throw new InvalidOperationException("Observed-text coordination failed.");
}

var ordered = new OrderedTextUpdateSession(policy, OrderedTextSource.Asr);
if (!ordered.Start("utterance-1"))
    throw new InvalidOperationException("Ordered text session did not start.");
var interim = ordered.Accept(new OrderedTextUpdateEvent(
    "utterance-1", 0, "中2文", TextStability.Interim));
if (interim.Output is not { DisplayText: "中 2 文", CommittedText: null })
    throw new InvalidOperationException("Interim output contract failed.");
var stale = ordered.Accept(new OrderedTextUpdateEvent(
    "utterance-1", 0, "ignored", TextStability.Interim));
if (stale is not { Accepted: false, Reason: OrderedTextUpdateReason.StaleRevision, Output: null })
    throw new InvalidOperationException("Stale revision contract failed.");
var final = ordered.Accept(new OrderedTextUpdateEvent(
    "utterance-1", 1, "中2文", TextStability.Final));
if (final.Output?.CommittedText != "中 2 文")
    throw new InvalidOperationException("Ordered text-update coordination failed.");
var afterFinal = ordered.Accept(new OrderedTextUpdateEvent(
    "utterance-1", 2, "ignored", TextStability.Final));
if (afterFinal.Reason != OrderedTextUpdateReason.InactiveUtterance)
    throw new InvalidOperationException("Final output must close the utterance.");
