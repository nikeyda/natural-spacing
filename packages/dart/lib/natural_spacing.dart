library;

import 'src/grapheme_17.dart';
import 'src/unicode_17_generated.dart';

enum FieldPolicy { naturalLanguage, verbatim }

enum EditKind { insert, delete, replace, paste }

enum PlanDecision {
  applied,
  noChange,
  verbatim,
  composing,
  suppressed,
  lengthLimited,
}

enum InsertionReason { hanLatin, hanAsciiDigit }

final class TextRange {
  const TextRange(this.start, this.length);

  final int start;
  final int length;

  @override
  bool operator ==(Object other) =>
      other is TextRange && start == other.start && length == other.length;

  @override
  int get hashCode => Object.hash(start, length);
}

final class TextSelection {
  const TextSelection(this.anchor, this.focus);

  final int anchor;
  final int focus;

  @override
  bool operator ==(Object other) =>
      other is TextSelection && anchor == other.anchor && focus == other.focus;

  @override
  int get hashCode => Object.hash(anchor, focus);
}

final class Insertion {
  const Insertion(this.offset, this.reason);

  final int offset;
  final InsertionReason reason;
  String get text => ' ';

  @override
  bool operator ==(Object other) =>
      other is Insertion && offset == other.offset && reason == other.reason;

  @override
  int get hashCode => Object.hash(offset, reason);
}

final class EditSnapshot {
  const EditSnapshot({
    required this.beforeText,
    required this.afterUserText,
    required this.changedRange,
    required this.selection,
    required this.composingRange,
    required this.editKind,
    required this.policy,
    required this.maxLengthUtf16,
  });

  final String beforeText;
  final String afterUserText;
  final TextRange changedRange;
  final TextSelection selection;
  final TextRange? composingRange;
  final EditKind editKind;
  final FieldPolicy policy;
  final int? maxLengthUtf16;
}

final class EditPlan {
  const EditPlan({
    required this.decision,
    required this.insertions,
    required this.resultText,
    required this.selection,
  });

  final PlanDecision decision;
  final List<Insertion> insertions;
  final String resultText;
  final TextSelection selection;
}

final class ProposedEdit {
  const ProposedEdit({
    required this.text,
    required this.range,
    required this.replacementText,
    required this.editKind,
    required this.policy,
    this.composingRange,
    this.selectionAfterEdit,
    this.maxLengthUtf16,
  });

  final String text;
  final TextRange range;
  final String replacementText;
  final EditKind editKind;
  final FieldPolicy policy;
  final TextRange? composingRange;
  final TextSelection? selectionAfterEdit;
  final int? maxLengthUtf16;
}

final class ProposedEditResult {
  const ProposedEditResult({
    required this.plan,
    required this.replacementText,
    required this.requiresReplacement,
  });

  final EditPlan plan;
  final String replacementText;
  final bool requiresReplacement;
}

enum ContentKind {
  prose,
  title,
  message,
  note,
  document,
  transcript,
  asrTranscript,
  code,
  identifier,
  url,
  email,
  password,
  token,
  filePath,
  command,
  number,
  searchQuery,
  unknown,
}

enum RecommendationConfidence { high, medium, low }

enum RecommendationSource {
  explicit,
  safety,
  contentKind,
  textHeuristic,
  fallback,
}

enum RecommendationReason {
  explicitPolicy,
  secureContent,
  naturalLanguageContent,
  structuredContent,
  ambiguousSearch,
  structuredText,
  mixedNaturalLanguage,
  insufficientEvidence,
}

final class PolicyContext {
  const PolicyContext({
    this.explicitPolicy,
    this.contentKind,
    this.text,
    this.isSecure,
  });

  final FieldPolicy? explicitPolicy;
  final ContentKind? contentKind;
  final String? text;
  final bool? isSecure;
}

final class PolicyRecommendation {
  const PolicyRecommendation({
    required this.policy,
    required this.confidence,
    required this.source,
    required this.reason,
    required this.autoApply,
  });

  final FieldPolicy policy;
  final RecommendationConfidence confidence;
  final RecommendationSource source;
  final RecommendationReason reason;
  final bool autoApply;

  @override
  bool operator ==(Object other) =>
      other is PolicyRecommendation &&
      policy == other.policy &&
      confidence == other.confidence &&
      source == other.source &&
      reason == other.reason &&
      autoApply == other.autoApply;

  @override
  int get hashCode =>
      Object.hash(policy, confidence, source, reason, autoApply);
}

enum TextSource { asr, dictation, imported, generated }

enum TextStability { interim, finalValue }

final class TextUpdate {
  const TextUpdate({
    required this.text,
    required this.policy,
    required this.source,
    required this.stability,
  });

  final String text;
  final FieldPolicy policy;
  final TextSource source;
  final TextStability stability;
}

final class FormattedTextUpdate {
  const FormattedTextUpdate({
    required this.displayText,
    required this.committedText,
    required this.changed,
    required this.policy,
    required this.source,
    required this.stability,
  });

  final String displayText;
  final String? committedText;
  final bool changed;
  final FieldPolicy policy;
  final TextSource source;
  final TextStability stability;

  @override
  bool operator ==(Object other) =>
      other is FormattedTextUpdate &&
      displayText == other.displayText &&
      committedText == other.committedText &&
      changed == other.changed &&
      policy == other.policy &&
      source == other.source &&
      stability == other.stability;

  @override
  int get hashCode => Object.hash(
    displayText,
    committedText,
    changed,
    policy,
    source,
    stability,
  );
}

enum OrderedTextSource { asr, dictation }

enum OrderedTextUpdateReason {
  accepted,
  inactiveUtterance,
  staleRevision,
  invalidRevision,
}

final class OrderedTextUpdateEvent {
  const OrderedTextUpdateEvent({
    required this.utteranceId,
    required this.revision,
    required this.text,
    required this.stability,
  });

  final String utteranceId;
  final int revision;
  final String text;
  final TextStability stability;
}

final class OrderedTextUpdateResult {
  const OrderedTextUpdateResult({
    required this.accepted,
    required this.reason,
    required this.output,
  });

  final bool accepted;
  final OrderedTextUpdateReason reason;
  final FormattedTextUpdate? output;

  @override
  bool operator ==(Object other) =>
      other is OrderedTextUpdateResult &&
      accepted == other.accepted &&
      reason == other.reason &&
      output == other.output;

  @override
  int get hashCode => Object.hash(accepted, reason, output);
}

/// Coordinates complete hypotheses from revision-capable ASR or dictation
/// providers while retaining only the active utterance ID and revision.
final class OrderedTextUpdateSession {
  OrderedTextUpdateSession({
    this.policy = FieldPolicy.naturalLanguage,
    this.source = OrderedTextSource.asr,
  });

  final FieldPolicy policy;
  final OrderedTextSource source;
  String? _activeUtteranceId;
  int _lastRevision = -1;

  bool start(String utteranceId) {
    if (utteranceId.isEmpty) return false;
    _activeUtteranceId = utteranceId;
    _lastRevision = -1;
    return true;
  }

  OrderedTextUpdateResult accept(OrderedTextUpdateEvent update) {
    if (update.revision < 0) {
      return _rejected(OrderedTextUpdateReason.invalidRevision);
    }
    if (_activeUtteranceId != update.utteranceId) {
      return _rejected(OrderedTextUpdateReason.inactiveUtterance);
    }
    if (update.revision <= _lastRevision) {
      return _rejected(OrderedTextUpdateReason.staleRevision);
    }

    _lastRevision = update.revision;
    final output = NaturalSpacingPolicy.format(
      TextUpdate(
        text: update.text,
        policy: policy,
        source: source == OrderedTextSource.asr
            ? TextSource.asr
            : TextSource.dictation,
        stability: update.stability,
      ),
    );
    if (update.stability == TextStability.finalValue) {
      _activeUtteranceId = null;
      _lastRevision = -1;
    }
    return OrderedTextUpdateResult(
      accepted: true,
      reason: OrderedTextUpdateReason.accepted,
      output: output,
    );
  }

  bool cancel(String utteranceId) {
    if (_activeUtteranceId != utteranceId) return false;
    _activeUtteranceId = null;
    _lastRevision = -1;
    return true;
  }

  OrderedTextUpdateResult _rejected(OrderedTextUpdateReason reason) =>
      OrderedTextUpdateResult(accepted: false, reason: reason, output: null);
}

abstract final class NaturalSpacing {
  static const unicodeVersion = '17.0.0';

  static String normalize(
    String text, {
    FieldPolicy policy = FieldPolicy.verbatim,
  }) => policy == FieldPolicy.naturalLanguage
      ? _apply(_eligibleInsertions(text), text)
      : text;

  static EditPlan planEdit(
    EditSnapshot snapshot, [
    Set<int> suppressedOffsets = const <int>{},
  ]) {
    if (snapshot.policy == FieldPolicy.verbatim) {
      return _unchanged(snapshot, PlanDecision.verbatim);
    }
    if (snapshot.composingRange != null) {
      return _unchanged(snapshot, PlanDecision.composing);
    }

    final replacementLength =
        snapshot.afterUserText.length -
        (snapshot.beforeText.length - snapshot.changedRange.length);
    final start = snapshot.changedRange.start;
    final end = start + replacementLength;
    final eligible = _eligibleInsertions(snapshot.afterUserText)
        .where((item) => item.offset >= start && item.offset <= end)
        .toList(growable: false);
    final insertions = eligible
        .where((item) => !suppressedOffsets.contains(item.offset))
        .toList(growable: false);
    if (insertions.isEmpty) {
      return _unchanged(
        snapshot,
        eligible.isEmpty ? PlanDecision.noChange : PlanDecision.suppressed,
      );
    }

    final result = _apply(insertions, snapshot.afterUserText);
    final limit = snapshot.maxLengthUtf16;
    if (limit != null && result.length > limit) {
      return _unchanged(snapshot, PlanDecision.lengthLimited);
    }
    return EditPlan(
      decision: PlanDecision.applied,
      insertions: insertions,
      resultText: result,
      selection: _mapSelection(snapshot.selection, insertions),
    );
  }

  static ProposedEditResult planProposedEdit(ProposedEdit edit) =>
      _processProposedEdit(edit, planEdit);

  static ProposedEdit? replacingDifference({
    required String beforeText,
    required String afterText,
    required FieldPolicy policy,
    TextSelection? selectionAfterEdit,
    int? maxLengthUtf16,
  }) {
    var prefix = 0;
    while (prefix < beforeText.length &&
        prefix < afterText.length &&
        beforeText.codeUnitAt(prefix) == afterText.codeUnitAt(prefix)) {
      prefix++;
    }
    var suffix = 0;
    while (suffix < beforeText.length - prefix &&
        suffix < afterText.length - prefix &&
        beforeText.codeUnitAt(beforeText.length - suffix - 1) ==
            afterText.codeUnitAt(afterText.length - suffix - 1)) {
      suffix++;
    }
    final oldLength = beforeText.length - prefix - suffix;
    final newLength = afterText.length - prefix - suffix;
    if (oldLength == 0 && newLength == 0) return null;
    final replacement = afterText.substring(prefix, prefix + newLength);
    final kind = replacement.isEmpty && oldLength > 0
        ? EditKind.delete
        : oldLength == 0
        ? EditKind.insert
        : EditKind.replace;
    return ProposedEdit(
      text: beforeText,
      range: TextRange(prefix, oldLength),
      replacementText: replacement,
      editKind: kind,
      policy: policy,
      selectionAfterEdit: selectionAfterEdit,
      maxLengthUtf16: maxLengthUtf16,
    );
  }

  static ProposedEditResult _processProposedEdit(
    ProposedEdit edit,
    EditPlan Function(EditSnapshot) planner,
  ) {
    if (edit.range.start < 0 ||
        edit.range.length < 0 ||
        edit.range.start > edit.text.length - edit.range.length) {
      throw RangeError('Proposed edit range is outside the UTF-16 text.');
    }
    final after = edit.text.replaceRange(
      edit.range.start,
      edit.range.start + edit.range.length,
      edit.replacementText,
    );
    final caret = edit.range.start + edit.replacementText.length;
    final plan = planner(
      EditSnapshot(
        beforeText: edit.text,
        afterUserText: after,
        changedRange: edit.range,
        selection: edit.selectionAfterEdit ?? TextSelection(caret, caret),
        composingRange: edit.composingRange,
        editKind: edit.editKind,
        policy: edit.policy,
        maxLengthUtf16: edit.maxLengthUtf16,
      ),
    );
    if (plan.decision != PlanDecision.applied) {
      return ProposedEditResult(
        plan: plan,
        replacementText: edit.replacementText,
        requiresReplacement: false,
      );
    }
    final relative = plan.insertions
        .map((item) => Insertion(item.offset - edit.range.start, item.reason))
        .toList(growable: false);
    return ProposedEditResult(
      plan: plan,
      replacementText: _apply(relative, edit.replacementText),
      requiresReplacement: true,
    );
  }

  static List<Insertion> _eligibleInsertions(String text) {
    final graphemes = _segment(text);
    final result = <Insertion>[];
    for (var index = 1; index < graphemes.length; index++) {
      final reason = _reason(
        graphemes[index - 1].category,
        graphemes[index].category,
      );
      if (reason != null) {
        result.add(Insertion(graphemes[index].start, reason));
      }
    }
    return result;
  }

  static TextSelection _mapSelection(
    TextSelection selection,
    List<Insertion> insertions,
  ) {
    int map(int value) =>
        value +
        insertions
            .where((item) => value >= item.offset)
            .fold(0, (total, item) => total + item.text.length);
    return TextSelection(map(selection.anchor), map(selection.focus));
  }

  static String _apply(List<Insertion> insertions, String text) {
    var result = text;
    for (final insertion in insertions.reversed) {
      result = result.replaceRange(
        insertion.offset,
        insertion.offset,
        insertion.text,
      );
    }
    return result;
  }

  static InsertionReason? _reason(_Category left, _Category right) {
    if ((left == _Category.han && right == _Category.latin) ||
        (left == _Category.latin && right == _Category.han)) {
      return InsertionReason.hanLatin;
    }
    if ((left == _Category.han && right == _Category.asciiDigit) ||
        (left == _Category.asciiDigit && right == _Category.han)) {
      return InsertionReason.hanAsciiDigit;
    }
    return null;
  }

  static List<_Grapheme> _segment(String text) {
    final result = <_Grapheme>[];
    final boundaries = Grapheme17.boundaries(text);
    for (var index = 1; index < boundaries.length; index++) {
      final start = boundaries[index - 1];
      final end = boundaries[index];
      final value = text.substring(start, end);
      result.add(_Grapheme(value, start, end, _classify(value)));
    }
    return result;
  }

  static _Category _classify(String grapheme) {
    final scalars = grapheme.runes.toList(growable: false);
    if (scalars.any(
      (value) => Unicode17.contains(Unicode17.whiteSpaceRanges, value),
    )) {
      return _Category.whitespace;
    }
    if (scalars.length == 1) {
      final value = scalars.single;
      if (value >= 0x30 && value <= 0x39) return _Category.asciiDigit;
    }
    int? base;
    for (final scalar in scalars) {
      if (!Unicode17.contains(Unicode17.markRanges, scalar)) {
        base = scalar;
        break;
      }
    }
    if (base == null) return _Category.other;
    if (Unicode17.contains(Unicode17.hanRanges, base)) return _Category.han;
    if (Unicode17.contains(Unicode17.latinRanges, base)) {
      return _Category.latin;
    }
    return _Category.other;
  }

  static EditPlan _unchanged(EditSnapshot snapshot, PlanDecision decision) =>
      EditPlan(
        decision: decision,
        insertions: const [],
        resultText: snapshot.afterUserText,
        selection: snapshot.selection,
      );
}

final class NaturalSpacingSession {
  var _suppressions = <_SuppressedBoundary>[];
  FieldPolicy? _lastPolicy;

  int get suppressedBoundaryCount => _suppressions.length;

  void reset() {
    _suppressions.clear();
    _lastPolicy = null;
  }

  EditPlan process(EditSnapshot snapshot) {
    if (_lastPolicy != null && _lastPolicy != snapshot.policy) {
      _suppressions.clear();
    }
    _lastPolicy = snapshot.policy;
    _rebase(snapshot);
    if (snapshot.policy == FieldPolicy.naturalLanguage &&
        snapshot.composingRange == null) {
      final boundary = _deletedBoundary(snapshot);
      if (boundary != null) {
        _suppressions.removeWhere((item) => item.offset == boundary.offset);
        _suppressions.add(boundary);
      }
    }

    final planned = NaturalSpacing.planEdit(
      snapshot,
      _suppressions.map((item) => item.offset).toSet(),
    );
    final plan =
        planned.decision == PlanDecision.noChange && _suppressions.isNotEmpty
        ? EditPlan(
            decision: PlanDecision.suppressed,
            insertions: planned.insertions,
            resultText: planned.resultText,
            selection: planned.selection,
          )
        : planned;
    _suppressions = _suppressions
        .map((suppression) {
          final mapped = NaturalSpacing._mapSelection(
            TextSelection(suppression.offset, suppression.offset),
            plan.insertions,
          ).anchor;
          final context = _boundaryContext(plan.resultText, mapped);
          return context != null &&
                  context.left == suppression.left &&
                  context.right == suppression.right
              ? _SuppressedBoundary(mapped, suppression.left, suppression.right)
              : null;
        })
        .whereType<_SuppressedBoundary>()
        .toList();
    return plan;
  }

  ProposedEditResult processProposedEdit(ProposedEdit edit) =>
      NaturalSpacing._processProposedEdit(edit, process);

  void _rebase(EditSnapshot snapshot) {
    final start = snapshot.changedRange.start;
    final end = start + snapshot.changedRange.length;
    final delta = snapshot.afterUserText.length - snapshot.beforeText.length;
    _suppressions = _suppressions
        .map((suppression) {
          var offset = suppression.offset;
          if (offset > end ||
              (snapshot.changedRange.length > 0 && offset == end)) {
            offset += delta;
          } else if (offset > start && offset < end) {
            return null;
          }
          final context = _boundaryContext(snapshot.afterUserText, offset);
          return context != null &&
                  context.left == suppression.left &&
                  context.right == suppression.right
              ? _SuppressedBoundary(offset, suppression.left, suppression.right)
              : null;
        })
        .whereType<_SuppressedBoundary>()
        .toList();
  }

  static _SuppressedBoundary? _deletedBoundary(EditSnapshot snapshot) {
    if (snapshot.editKind != EditKind.delete ||
        snapshot.changedRange.length != 1 ||
        snapshot.beforeText.length - 1 != snapshot.afterUserText.length ||
        snapshot.beforeText.substring(
              snapshot.changedRange.start,
              snapshot.changedRange.start + 1,
            ) !=
            ' ') {
      return null;
    }
    final context = _boundaryContext(
      snapshot.afterUserText,
      snapshot.changedRange.start,
    );
    return context != null &&
            NaturalSpacing._reason(
                  context.leftCategory,
                  context.rightCategory,
                ) !=
                null
        ? _SuppressedBoundary(
            snapshot.changedRange.start,
            context.left,
            context.right,
          )
        : null;
  }

  static _Boundary? _boundaryContext(String text, int offset) {
    final graphemes = NaturalSpacing._segment(text);
    final rightIndex = graphemes.indexWhere((item) => item.start == offset);
    if (rightIndex <= 0) return null;
    final left = graphemes[rightIndex - 1];
    final right = graphemes[rightIndex];
    return left.end == offset
        ? _Boundary(left.text, right.text, left.category, right.category)
        : null;
  }
}

abstract final class NaturalSpacingPolicy {
  static const _naturalKinds = {
    ContentKind.prose,
    ContentKind.title,
    ContentKind.message,
    ContentKind.note,
    ContentKind.document,
    ContentKind.transcript,
    ContentKind.asrTranscript,
  };
  static const _verbatimKinds = {
    ContentKind.code,
    ContentKind.identifier,
    ContentKind.url,
    ContentKind.email,
    ContentKind.password,
    ContentKind.token,
    ContentKind.filePath,
    ContentKind.command,
    ContentKind.number,
  };
  static final _structuredPatterns = [
    RegExp(r'^(?:[a-z][a-z0-9+.-]*://|www\.)', caseSensitive: false),
    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$', caseSensitive: false),
    RegExp(r'^(?:[A-Za-z]:[\\/]|~?[\\/])'),
    RegExp(r'^(?:[A-Za-z_$][A-Za-z0-9_$-]*[.:/@\\])+[A-Za-z0-9_$.-]+$'),
    RegExp(r'(?:=>|::|</?[A-Za-z][^>]*>|\{[^}]*\}|`[^`]*`)'),
  ];

  static PolicyRecommendation recommend([
    PolicyContext context = const PolicyContext(),
  ]) {
    if (context.isSecure == true ||
        context.contentKind == ContentKind.password) {
      return _result(
        FieldPolicy.verbatim,
        RecommendationConfidence.high,
        RecommendationSource.safety,
        RecommendationReason.secureContent,
        true,
      );
    }
    final explicit = context.explicitPolicy;
    if (explicit != null) {
      return _result(
        explicit,
        RecommendationConfidence.high,
        RecommendationSource.explicit,
        RecommendationReason.explicitPolicy,
        true,
      );
    }
    final kind = context.contentKind ?? ContentKind.unknown;
    if (_naturalKinds.contains(kind)) {
      return _result(
        FieldPolicy.naturalLanguage,
        RecommendationConfidence.high,
        RecommendationSource.contentKind,
        RecommendationReason.naturalLanguageContent,
        true,
      );
    }
    if (_verbatimKinds.contains(kind)) {
      return _result(
        FieldPolicy.verbatim,
        RecommendationConfidence.high,
        RecommendationSource.contentKind,
        RecommendationReason.structuredContent,
        true,
      );
    }
    final value = context.text?.trim();
    if (value != null &&
        value.isNotEmpty &&
        _structuredPatterns.any((pattern) => pattern.hasMatch(value))) {
      return _result(
        FieldPolicy.verbatim,
        RecommendationConfidence.medium,
        RecommendationSource.textHeuristic,
        RecommendationReason.structuredText,
        false,
      );
    }
    if (kind == ContentKind.searchQuery) {
      return _result(
        FieldPolicy.naturalLanguage,
        RecommendationConfidence.medium,
        RecommendationSource.contentKind,
        RecommendationReason.ambiguousSearch,
        false,
      );
    }
    if (context.text != null &&
        NaturalSpacing._eligibleInsertions(context.text!).isNotEmpty) {
      return _result(
        FieldPolicy.naturalLanguage,
        RecommendationConfidence.medium,
        RecommendationSource.textHeuristic,
        RecommendationReason.mixedNaturalLanguage,
        false,
      );
    }
    return _result(
      FieldPolicy.verbatim,
      RecommendationConfidence.low,
      RecommendationSource.fallback,
      RecommendationReason.insufficientEvidence,
      false,
    );
  }

  static FieldPolicy resolve([
    PolicyContext context = const PolicyContext(),
    FieldPolicy fallback = FieldPolicy.verbatim,
  ]) {
    final recommended = recommend(context);
    return recommended.autoApply ? recommended.policy : fallback;
  }

  static FormattedTextUpdate format(TextUpdate update) {
    final display = NaturalSpacing.normalize(
      update.text,
      policy: update.policy,
    );
    return FormattedTextUpdate(
      displayText: display,
      committedText: update.stability == TextStability.finalValue
          ? display
          : null,
      changed: display != update.text,
      policy: update.policy,
      source: update.source,
      stability: update.stability,
    );
  }

  static PolicyRecommendation _result(
    FieldPolicy policy,
    RecommendationConfidence confidence,
    RecommendationSource source,
    RecommendationReason reason,
    bool autoApply,
  ) => PolicyRecommendation(
    policy: policy,
    confidence: confidence,
    source: source,
    reason: reason,
    autoApply: autoApply,
  );
}

enum _Category { han, latin, asciiDigit, whitespace, other }

final class _Grapheme {
  const _Grapheme(this.text, this.start, this.end, this.category);

  final String text;
  final int start;
  final int end;
  final _Category category;
}

final class _SuppressedBoundary {
  const _SuppressedBoundary(this.offset, this.left, this.right);

  final int offset;
  final String left;
  final String right;
}

final class _Boundary {
  const _Boundary(this.left, this.right, this.leftCategory, this.rightCategory);

  final String left;
  final String right;
  final _Category leftCategory;
  final _Category rightCategory;
}
