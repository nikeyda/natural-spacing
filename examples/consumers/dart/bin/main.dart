import 'package:natural_spacing/natural_spacing.dart';

void main() {
  const context = PolicyContext(contentKind: ContentKind.message);
  final recommendation = NaturalSpacingPolicy.recommend(context);
  final policy = NaturalSpacingPolicy.resolve(context);
  final normalized = NaturalSpacing.normalize('发布v2版本', policy: policy);

  if (!recommendation.autoApply ||
      policy != FieldPolicy.naturalLanguage ||
      normalized != '发布 v2 版本') {
    throw StateError('Natural-language policy consumption failed.');
  }

  const advisory = PolicyContext(
    contentKind: ContentKind.searchQuery,
    text: '发布v2版本',
  );
  if (NaturalSpacingPolicy.resolve(advisory) != FieldPolicy.verbatim) {
    throw StateError('Advisory policy must use the safe fallback.');
  }

  const secure = PolicyContext(
    explicitPolicy: FieldPolicy.naturalLanguage,
    contentKind: ContentKind.message,
    isSecure: true,
  );
  if (NaturalSpacingPolicy.resolve(secure) != FieldPolicy.verbatim) {
    throw StateError('Secure input must override natural-language policy.');
  }

  final ordered = OrderedTextUpdateSession(policy: policy);
  if (!ordered.start('utterance-1')) {
    throw StateError('Ordered text session did not start.');
  }
  final interim = ordered.accept(
    const OrderedTextUpdateEvent(
      utteranceId: 'utterance-1',
      revision: 0,
      text: '中2文',
      stability: TextStability.interim,
    ),
  );
  if (interim.output?.displayText != '中 2 文' ||
      interim.output?.committedText != null) {
    throw StateError('Interim output contract failed.');
  }
  final stale = ordered.accept(
    const OrderedTextUpdateEvent(
      utteranceId: 'utterance-1',
      revision: 0,
      text: 'ignored',
      stability: TextStability.interim,
    ),
  );
  if (stale.accepted || stale.output != null) {
    throw StateError('Stale revision contract failed.');
  }
  final finalResult = ordered.accept(
    const OrderedTextUpdateEvent(
      utteranceId: 'utterance-1',
      revision: 1,
      text: '中2文',
      stability: TextStability.finalValue,
    ),
  );
  if (finalResult.output?.committedText != '中 2 文') {
    throw StateError('Ordered text-update coordination failed.');
  }
  final afterFinal = ordered.accept(
    const OrderedTextUpdateEvent(
      utteranceId: 'utterance-1',
      revision: 2,
      text: 'ignored',
      stability: TextStability.finalValue,
    ),
  );
  if (afterFinal.reason != OrderedTextUpdateReason.inactiveUtterance) {
    throw StateError('Final output must close the utterance.');
  }
}
