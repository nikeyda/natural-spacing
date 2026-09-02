using System.Text.Json;
using System.Text;
using NaturalSpacing.Core;

if (args.Length != 1)
{
    Console.Error.WriteLine("Usage: NaturalSpacing.Conformance <repository-root>");
    return 2;
}

var fixtures = Path.Combine(Path.GetFullPath(args[0]), "spec", "fixtures");
var checks = 0;

foreach (var value in Cases("rules-v1.json", "cases"))
{
    var id = String(value, "id");
    var policy = Enum<FieldPolicy>(value, "policy");
    var expected = String(value, "expected");
    var actual = NaturalSpacingFormatter.Normalize(String(value, "input"), policy);
    Require(actual == expected, $"{id}: expected '{expected}', got '{actual}'");
    Require(NaturalSpacingFormatter.Normalize(actual, policy) == actual, $"{id}: not idempotent");
    checks++;
}

foreach (var scenario in Cases("sessions-v1.json", "scenarios"))
{
    var session = new NaturalSpacingSession();
    var index = 0;
    foreach (var step in scenario.GetProperty("steps").EnumerateArray())
    {
        index++;
        var exchange = step.GetProperty("exchange");
        var actual = session.Process(Snapshot(exchange.GetProperty("snapshot")));
        var expected = Plan(exchange.GetProperty("expectedPlan"));
        Require(SamePlan(actual, expected), $"{String(scenario, "id")} step {index}: {actual} != {expected}");
        var count = step.GetProperty("expectedSession").GetProperty("suppressedBoundaryCount").GetInt32();
        Require(session.SuppressedBoundaryCount == count,
            $"{String(scenario, "id")} step {index}: suppression count {session.SuppressedBoundaryCount} != {count}");
        checks++;
    }
}

foreach (var value in Cases("policy-v1.json", "cases"))
{
    var context = PolicyContext(value.GetProperty("context"));
    var actual = NaturalSpacingPolicy.Recommend(context);
    var expected = Recommendation(value.GetProperty("expected"));
    Require(actual == expected, $"{String(value, "id")}: {actual} != {expected}");
    var resolved = NaturalSpacingPolicy.Resolve(context);
    Require(resolved == (expected.AutoApply ? expected.Policy : FieldPolicy.Verbatim),
        $"{String(value, "id")}: unsafe automatic resolution {resolved}");
    if (String(value, "id") == "search-query-is-a-recommendation")
        Require(NaturalSpacingPolicy.Resolve(context, FieldPolicy.NaturalLanguage) == FieldPolicy.NaturalLanguage,
            "search query custom fallback");
    checks++;
}

foreach (var value in Cases("text-updates-v1.json", "cases"))
{
    var actual = NaturalSpacingPolicy.Format(TextUpdate(value.GetProperty("update")));
    var expected = FormattedTextUpdate(value.GetProperty("expected"));
    Require(actual == expected, $"{String(value, "id")}: {actual} != {expected}");
    checks++;
}

var orderedChecks = 0;
foreach (var scenario in Cases("ordered-text-sessions-v1.json", "scenarios"))
{
    var orderedSession = new OrderedTextUpdateSession(
        Enum<FieldPolicy>(scenario, "policy"),
        Enum<OrderedTextSource>(scenario, "source"));
    var index = 0;
    foreach (var operation in scenario.GetProperty("operations").EnumerateArray())
    {
        index++;
        var expected = operation.GetProperty("expected");
        switch (String(operation, "kind"))
        {
            case "start":
                Require(
                    orderedSession.Start(String(operation, "utteranceId")) ==
                    expected.GetProperty("started").GetBoolean(),
                    $"{String(scenario, "id")} operation {index}: start");
                break;
            case "cancel":
                Require(
                    orderedSession.Cancel(String(operation, "utteranceId")) ==
                    expected.GetProperty("cancelled").GetBoolean(),
                    $"{String(scenario, "id")} operation {index}: cancel");
                break;
            case "accept":
                var actual = orderedSession.Accept(OrderedTextEvent(operation.GetProperty("event")));
                var expectedResult = OrderedTextResult(expected);
                Require(actual == expectedResult,
                    $"{String(scenario, "id")} operation {index}: {actual} != {expectedResult}");
                break;
            default:
                throw new InvalidOperationException("Unknown ordered text operation");
        }
        orderedChecks++;
    }
}

var proposed = NaturalSpacingFormatter.PlanProposedEdit(new ProposedEdit(
    "中文", new TextRange(1, 0), "A", EditKind.Insert, FieldPolicy.NaturalLanguage));
Require(proposed.ReplacementText == " A " && proposed.Plan.ResultText == "中 A 文", "proposed edit fragment");

var difference = NaturalSpacingFormatter.ReplacingDifference(
    "中🙂文", "中🙂A文", FieldPolicy.NaturalLanguage);
Require(difference is not null && difference.Range == new TextRange(3, 0) && difference.ReplacementText == "A",
    "minimal UTF-16 replacement difference");

var deletionSession = new NaturalSpacingSession();
var deletion = deletionSession.ProcessProposedEdit(new ProposedEdit(
    "中 A", new TextRange(1, 1), "", EditKind.Delete, FieldPolicy.NaturalLanguage));
Require(deletion.Plan.Decision == PlanDecision.Suppressed && !deletion.RequiresReplacement,
    "manual auto-space deletion suppression");

var composing = NaturalSpacingFormatter.PlanProposedEdit(new ProposedEdit(
    "中", new TextRange(1, 0), "A", EditKind.Insert, FieldPolicy.NaturalLanguage,
    ComposingRange: new TextRange(1, 1)));
Require(composing.Plan.Decision == PlanDecision.Composing && !composing.RequiresReplacement,
    "composition pass-through");
checks += 4;

var observedChecks = 0;
var observed = new NaturalSpacingObservedTextSession("中文");
var observedDigit = observed.Reconcile(
    "中2文", FieldPolicy.NaturalLanguage, new TextSelection(2, 2));
Require(observedDigit is { RequiresReplacement: true } &&
        observedDigit.Plan.ResultText == "中 2 文" &&
        observedDigit.Plan.Selection == new TextSelection(4, 4),
    "observed text digit insertion");
observedChecks++;

var observedDeletion = observed.Reconcile(
    "中2 文", FieldPolicy.NaturalLanguage, new TextSelection(1, 1));
Require(observedDeletion is { RequiresReplacement: false } &&
        observedDeletion.Plan.Decision == PlanDecision.Suppressed &&
        observed.SettledText == "中2 文",
    "observed text deletion suppression");
observedChecks++;

observed.Sync("版本");
var observedAfterSync = observed.Reconcile(
    "版2本", FieldPolicy.NaturalLanguage, new TextSelection(2, 2));
Require(observedAfterSync is { RequiresReplacement: true } &&
        observedAfterSync.Plan.ResultText == "版 2 本",
    "observed text external sync");
observedChecks++;

var observedComposition = new NaturalSpacingObservedTextSession("中文");
Require(observedComposition.Reconcile(
        "中2文", FieldPolicy.NaturalLanguage, new TextSelection(2, 2), isComposing: true) is null &&
        observedComposition.SettledText == "中文",
    "observed text composition deferral");
var observedAfterComposition = observedComposition.Reconcile(
    "中2文", FieldPolicy.NaturalLanguage, new TextSelection(2, 2));
Require(observedAfterComposition is { RequiresReplacement: true } &&
        observedAfterComposition.Plan.ResultText == "中 2 文",
    "observed text composition settlement");
observedChecks++;

var observedVerbatim = new NaturalSpacingObservedTextSession("中文");
var verbatimResult = observedVerbatim.Reconcile(
    "中2文", FieldPolicy.Verbatim, new TextSelection(2, 2));
Require(verbatimResult is { RequiresReplacement: false } &&
        verbatimResult.Plan.Decision == PlanDecision.Verbatim &&
        observedVerbatim.SettledText == "中2文",
    "observed text verbatim baseline");
observedChecks++;

var observedLength = new NaturalSpacingObservedTextSession("中");
var lengthResult = observedLength.Reconcile(
    "中2", FieldPolicy.NaturalLanguage, new TextSelection(2, 2), maxLengthUtf16: 2);
Require(lengthResult is { RequiresReplacement: false } &&
        lengthResult.Plan.Decision == PlanDecision.LengthLimited &&
        observedLength.SettledText == "中2",
    "observed text length limit fail-open");
observedChecks++;

var observedRejectedApplication = new NaturalSpacingObservedTextSession("中");
var rejectedApplication = observedRejectedApplication.Reconcile(
    "中A", FieldPolicy.NaturalLanguage, new TextSelection(2, 2));
Require(rejectedApplication is { RequiresReplacement: true } &&
        rejectedApplication.Plan.ResultText == "中 A",
    "observed text proposes a host replacement");
observedRejectedApplication.Sync("中A");
var afterRejectedApplication = observedRejectedApplication.Reconcile(
    "中AB", FieldPolicy.NaturalLanguage, new TextSelection(3, 3));
Require(afterRejectedApplication is { RequiresReplacement: false } &&
        afterRejectedApplication.Plan.Decision == PlanDecision.NoChange &&
        observedRejectedApplication.SettledText == "中AB",
    "observed text resynchronizes after a rejected host replacement");
observedChecks++;

var graphemeChecks = 0;
var graphemeFile = Path.Combine(Path.GetFullPath(args[0]), "spec", "unicode", "17.0.0", "GraphemeBreakTest.txt");
foreach (var line in File.ReadLines(graphemeFile))
{
    var payload = line.Split('#', 2)[0].Trim();
    if (payload.Length == 0) continue;
    var text = new StringBuilder();
    var expected = new List<int>();
    var offset = 0;
    foreach (var token in payload.Split(' ', StringSplitOptions.RemoveEmptyEntries))
    {
        if (token == "÷") expected.Add(offset);
        else if (token != "×")
        {
            var rune = new Rune(Convert.ToInt32(token, 16));
            text.Append(rune.ToString());
            offset += rune.Utf16SequenceLength;
        }
    }
    Require(Grapheme17.Boundaries(text.ToString()).SequenceEqual(expected), line);
    graphemeChecks++;
}
Require(graphemeChecks == 766, $"expected 766 grapheme cases, got {graphemeChecks}");

var unicodeCases = new[]
{
    (Input: "中K", Expected: "中 K", Name: "Kelvin sign is a Latin letter"),
    (Input: "〡A", Expected: "〡 A", Name: "Hangzhou numeral one is Han Nl"),
    (Input: "〆A", Expected: "〆 A", Name: "ideographic closing mark is Han Lo through Script_Extensions"),
    (Input: "中˗", Expected: "中˗", Name: "Latin Script_Extensions alone does not admit a symbol"),
    (Input: "\u0363中", Expected: "\u0363中", Name: "a mark-only grapheme has no base"),
};
foreach (var item in unicodeCases)
{
    Require(
        NaturalSpacingFormatter.Normalize(item.Input, FieldPolicy.NaturalLanguage) == item.Expected,
        item.Name);
    checks++;
}

Console.WriteLine($"C# conformance passed: {checks - 4 - unicodeCases.Length} shared fixture checks + " +
    $"4 bridge checks + {unicodeCases.Length} generated Unicode checks + " +
    $"{observedChecks} observed-text coordinator checks + " +
    $"{orderedChecks} ordered text-update checks + " +
    $"{graphemeChecks} Unicode 17 grapheme checks, " +
    $".NET {Environment.Version}");
return 0;

IEnumerable<JsonElement> Cases(string file, string property)
{
    using var document = JsonDocument.Parse(File.ReadAllText(Path.Combine(fixtures, file)));
    return document.RootElement.GetProperty(property).EnumerateArray().Select(item => item.Clone()).ToArray();
}

static EditSnapshot Snapshot(JsonElement value) => new(
    String(value, "beforeText"),
    String(value, "afterUserText"),
    Range(value.GetProperty("changedRange")),
    Selection(value.GetProperty("selection")),
    NullableObject(value, "composingRange") is { } composingRange ? Range(composingRange) : null,
    Enum<EditKind>(value, "editKind"),
    Enum<FieldPolicy>(value, "policy"),
    NullableInt(value, "maxLengthUtf16"));

static EditPlan Plan(JsonElement value) => new(
    Enum<PlanDecision>(value, "decision"),
    value.GetProperty("insertions").EnumerateArray().Select(item =>
        new Insertion(item.GetProperty("offset").GetInt32(), Enum<InsertionReason>(item, "reason"))).ToArray(),
    String(value, "resultText"),
    Selection(value.GetProperty("selection")));

static PolicyContext PolicyContext(JsonElement value) => new(
    NullableEnum<FieldPolicy>(value, "explicitPolicy"),
    NullableEnum<ContentKind>(value, "contentKind"),
    NullableString(value, "text"),
    NullableBool(value, "isSecure"));

static PolicyRecommendation Recommendation(JsonElement value) => new(
    Enum<FieldPolicy>(value, "policy"),
    Enum<RecommendationConfidence>(value, "confidence"),
    Enum<RecommendationSource>(value, "source"),
    Enum<RecommendationReason>(value, "reason"),
    value.GetProperty("autoApply").GetBoolean());

static TextUpdate TextUpdate(JsonElement value) => new(
    String(value, "text"),
    Enum<FieldPolicy>(value, "policy"),
    Enum<TextSource>(value, "source"),
    Enum<TextStability>(value, "stability"));

static FormattedTextUpdate FormattedTextUpdate(JsonElement value) => new(
    String(value, "displayText"),
    NullableString(value, "committedText"),
    value.GetProperty("changed").GetBoolean(),
    Enum<FieldPolicy>(value, "policy"),
    Enum<TextSource>(value, "source"),
    Enum<TextStability>(value, "stability"));

static OrderedTextUpdateEvent OrderedTextEvent(JsonElement value) => new(
    String(value, "utteranceId"),
    value.GetProperty("revision").GetInt64(),
    String(value, "text"),
    Enum<TextStability>(value, "stability"));

static OrderedTextUpdateResult OrderedTextResult(JsonElement value) => new(
    value.GetProperty("accepted").GetBoolean(),
    Enum<OrderedTextUpdateReason>(value, "reason"),
    NullableObject(value, "output") is { } output ? FormattedTextUpdate(output) : null);

static TextRange Range(JsonElement value) =>
    new(value.GetProperty("start").GetInt32(), value.GetProperty("length").GetInt32());

static TextSelection Selection(JsonElement value) =>
    new(value.GetProperty("anchor").GetInt32(), value.GetProperty("focus").GetInt32());

static bool SamePlan(EditPlan left, EditPlan right) =>
    left.Decision == right.Decision &&
    left.ResultText == right.ResultText &&
    left.Selection == right.Selection &&
    left.Insertions.SequenceEqual(right.Insertions);

static T Enum<T>(JsonElement value, string property) where T : struct, Enum =>
    System.Enum.Parse<T>(String(value, property), ignoreCase: true);

static T? NullableEnum<T>(JsonElement value, string property) where T : struct, Enum =>
    NullableString(value, property) is { } text ? System.Enum.Parse<T>(text, ignoreCase: true) : null;

static string String(JsonElement value, string property) => value.GetProperty(property).GetString()!;

static string? NullableString(JsonElement value, string property) =>
    value.TryGetProperty(property, out var item) && item.ValueKind != JsonValueKind.Null ? item.GetString() : null;

static int? NullableInt(JsonElement value, string property) =>
    value.TryGetProperty(property, out var item) && item.ValueKind != JsonValueKind.Null ? item.GetInt32() : null;

static bool? NullableBool(JsonElement value, string property) =>
    value.TryGetProperty(property, out var item) && item.ValueKind != JsonValueKind.Null ? item.GetBoolean() : null;

static JsonElement? NullableObject(JsonElement value, string property) =>
    value.TryGetProperty(property, out var item) && item.ValueKind != JsonValueKind.Null ? item : null;

static void Require(bool condition, string message)
{
    if (!condition) throw new InvalidOperationException(message);
}
