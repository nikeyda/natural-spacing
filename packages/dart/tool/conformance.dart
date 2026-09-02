import 'dart:convert';
import 'dart:io';

import 'package:natural_spacing/natural_spacing.dart';
import 'package:natural_spacing/src/grapheme_17.dart';

void main(List<String> arguments) {
  if (arguments.length != 1) {
    stderr.writeln('Usage: dart run tool/conformance.dart <repository-root>');
    exitCode = 2;
    return;
  }

  final fixtures = Directory(
    '${Directory(arguments.single).absolute.path}/spec/fixtures',
  );
  var checks = 0;

  for (final value in _cases(fixtures, 'rules-v1.json', 'cases')) {
    final id = _string(value, 'id');
    final policy = _enum(FieldPolicy.values, _string(value, 'policy'));
    final expected = _string(value, 'expected');
    final actual = NaturalSpacing.normalize(
      _string(value, 'input'),
      policy: policy,
    );
    _require(actual == expected, "$id: expected '$expected', got '$actual'");
    _require(
      NaturalSpacing.normalize(actual, policy: policy) == actual,
      '$id: not idempotent',
    );
    checks++;
  }

  for (final scenario in _cases(fixtures, 'sessions-v1.json', 'scenarios')) {
    final session = NaturalSpacingSession();
    final steps = _list(scenario, 'steps');
    for (var index = 0; index < steps.length; index++) {
      final step = _map(steps[index]);
      final exchange = _map(step['exchange']);
      final actual = session.process(_snapshot(_map(exchange['snapshot'])));
      final expected = _plan(_map(exchange['expectedPlan']));
      _require(
        _samePlan(actual, expected),
        '${_string(scenario, 'id')} step ${index + 1}: plan mismatch',
      );
      final count = _int(
        _map(step['expectedSession']),
        'suppressedBoundaryCount',
      );
      _require(
        session.suppressedBoundaryCount == count,
        '${_string(scenario, 'id')} step ${index + 1}: '
        'suppression count ${session.suppressedBoundaryCount} != $count',
      );
      checks++;
    }
  }

  for (final value in _cases(fixtures, 'policy-v1.json', 'cases')) {
    final context = _policyContext(_map(value['context']));
    final actual = NaturalSpacingPolicy.recommend(context);
    final expected = _recommendation(_map(value['expected']));
    _require(
      actual == expected,
      '${_string(value, 'id')}: recommendation mismatch',
    );
    final resolved = NaturalSpacingPolicy.resolve(context);
    _require(
      resolved == (expected.autoApply ? expected.policy : FieldPolicy.verbatim),
      '${_string(value, 'id')}: unsafe automatic resolution',
    );
    if (_string(value, 'id') == 'search-query-is-a-recommendation') {
      _require(
        NaturalSpacingPolicy.resolve(context, FieldPolicy.naturalLanguage) ==
            FieldPolicy.naturalLanguage,
        'search query custom fallback',
      );
    }
    checks++;
  }

  for (final value in _cases(fixtures, 'text-updates-v1.json', 'cases')) {
    final actual = NaturalSpacingPolicy.format(
      _textUpdate(_map(value['update'])),
    );
    final expected = _formattedTextUpdate(_map(value['expected']));
    _require(
      actual == expected,
      '${_string(value, 'id')}: text update mismatch',
    );
    checks++;
  }

  var orderedChecks = 0;
  for (final scenario in _cases(
    fixtures,
    'ordered-text-sessions-v1.json',
    'scenarios',
  )) {
    final orderedSession = OrderedTextUpdateSession(
      policy: _enum(FieldPolicy.values, _string(scenario, 'policy')),
      source: _enum(OrderedTextSource.values, _string(scenario, 'source')),
    );
    final operations = _list(scenario, 'operations');
    for (var index = 0; index < operations.length; index++) {
      final operation = _map(operations[index]);
      final expected = _map(operation['expected']);
      switch (_string(operation, 'kind')) {
        case 'start':
          _require(
            orderedSession.start(_string(operation, 'utteranceId')) ==
                expected['started'],
            '${_string(scenario, 'id')} operation ${index + 1}: start',
          );
        case 'cancel':
          _require(
            orderedSession.cancel(_string(operation, 'utteranceId')) ==
                expected['cancelled'],
            '${_string(scenario, 'id')} operation ${index + 1}: cancel',
          );
        case 'accept':
          final actual = orderedSession.accept(
            _orderedTextUpdateEvent(_map(operation['event'])),
          );
          final expectedResult = _orderedTextUpdateResult(expected);
          _require(
            actual == expectedResult,
            '${_string(scenario, 'id')} operation ${index + 1}: '
            '$actual != $expectedResult',
          );
        default:
          throw StateError('Unknown ordered text operation');
      }
      orderedChecks++;
    }
  }

  final proposed = NaturalSpacing.planProposedEdit(
    const ProposedEdit(
      text: '中文',
      range: TextRange(1, 0),
      replacementText: 'A',
      editKind: EditKind.insert,
      policy: FieldPolicy.naturalLanguage,
    ),
  );
  _require(
    proposed.replacementText == ' A ' && proposed.plan.resultText == '中 A 文',
    'proposed edit fragment',
  );

  final difference = NaturalSpacing.replacingDifference(
    beforeText: '中🙂文',
    afterText: '中🙂A文',
    policy: FieldPolicy.naturalLanguage,
  );
  _require(
    difference != null &&
        difference.range == const TextRange(3, 0) &&
        difference.replacementText == 'A',
    'minimal UTF-16 replacement difference',
  );

  final deletionSession = NaturalSpacingSession();
  final deletion = deletionSession.processProposedEdit(
    const ProposedEdit(
      text: '中 A',
      range: TextRange(1, 1),
      replacementText: '',
      editKind: EditKind.delete,
      policy: FieldPolicy.naturalLanguage,
    ),
  );
  _require(
    deletion.plan.decision == PlanDecision.suppressed &&
        !deletion.requiresReplacement,
    'manual auto-space deletion suppression',
  );

  final composing = NaturalSpacing.planProposedEdit(
    const ProposedEdit(
      text: '中',
      range: TextRange(1, 0),
      replacementText: 'A',
      editKind: EditKind.insert,
      policy: FieldPolicy.naturalLanguage,
      composingRange: TextRange(1, 1),
    ),
  );
  _require(
    composing.plan.decision == PlanDecision.composing &&
        !composing.requiresReplacement,
    'composition pass-through',
  );
  checks += 4;

  var graphemeChecks = 0;
  final graphemeFile = File(
    '${Directory(arguments.single).absolute.path}/spec/unicode/17.0.0/'
    'GraphemeBreakTest.txt',
  );
  for (final line in graphemeFile.readAsLinesSync()) {
    final payload = line.split('#').first.trim();
    if (payload.isEmpty) continue;
    final text = StringBuffer();
    final expected = <int>[];
    var offset = 0;
    for (final token in payload.split(RegExp(r'\s+'))) {
      if (token == '÷') {
        expected.add(offset);
      } else if (token != '×') {
        final codePoint = int.parse(token, radix: 16);
        text.writeCharCode(codePoint);
        offset += codePoint > 0xffff ? 2 : 1;
      }
    }
    _require(_sameList(Grapheme17.boundaries(text.toString()), expected), line);
    graphemeChecks++;
  }
  _require(graphemeChecks == 766, 'expected 766 grapheme cases');

  stdout.writeln(
    'Dart conformance passed: ${checks - 4} shared fixture checks + '
    '4 bridge checks + $orderedChecks ordered text-update checks + '
    '$graphemeChecks Unicode 17 grapheme checks, '
    'Dart ${Platform.version.split(' ').first}',
  );
}

List<Map<String, Object?>> _cases(
  Directory fixtures,
  String file,
  String property,
) {
  final document = _map(
    jsonDecode(File('${fixtures.path}/$file').readAsStringSync()),
  );
  return _list(document, property).map(_map).toList(growable: false);
}

EditSnapshot _snapshot(Map<String, Object?> value) => EditSnapshot(
  beforeText: _string(value, 'beforeText'),
  afterUserText: _string(value, 'afterUserText'),
  changedRange: _range(_map(value['changedRange'])),
  selection: _selection(_map(value['selection'])),
  composingRange: value['composingRange'] == null
      ? null
      : _range(_map(value['composingRange'])),
  editKind: _enum(EditKind.values, _string(value, 'editKind')),
  policy: _enum(FieldPolicy.values, _string(value, 'policy')),
  maxLengthUtf16: value['maxLengthUtf16'] as int?,
);

EditPlan _plan(Map<String, Object?> value) => EditPlan(
  decision: _enum(PlanDecision.values, _string(value, 'decision')),
  insertions: _list(value, 'insertions')
      .map(_map)
      .map(
        (item) => Insertion(
          _int(item, 'offset'),
          _enum(InsertionReason.values, _string(item, 'reason')),
        ),
      )
      .toList(growable: false),
  resultText: _string(value, 'resultText'),
  selection: _selection(_map(value['selection'])),
);

PolicyContext _policyContext(Map<String, Object?> value) => PolicyContext(
  explicitPolicy: _nullableEnum(
    FieldPolicy.values,
    value['explicitPolicy'] as String?,
  ),
  contentKind: _nullableEnum(
    ContentKind.values,
    value['contentKind'] as String?,
  ),
  text: value['text'] as String?,
  isSecure: value['isSecure'] as bool?,
);

PolicyRecommendation _recommendation(Map<String, Object?> value) =>
    PolicyRecommendation(
      policy: _enum(FieldPolicy.values, _string(value, 'policy')),
      confidence: _enum(
        RecommendationConfidence.values,
        _string(value, 'confidence'),
      ),
      source: _enum(RecommendationSource.values, _string(value, 'source')),
      reason: _enum(RecommendationReason.values, _string(value, 'reason')),
      autoApply: value['autoApply']! as bool,
    );

TextUpdate _textUpdate(Map<String, Object?> value) => TextUpdate(
  text: _string(value, 'text'),
  policy: _enum(FieldPolicy.values, _string(value, 'policy')),
  source: _enum(TextSource.values, _string(value, 'source')),
  stability: _stability(_string(value, 'stability')),
);

FormattedTextUpdate _formattedTextUpdate(Map<String, Object?> value) =>
    FormattedTextUpdate(
      displayText: _string(value, 'displayText'),
      committedText: value['committedText'] as String?,
      changed: value['changed']! as bool,
      policy: _enum(FieldPolicy.values, _string(value, 'policy')),
      source: _enum(TextSource.values, _string(value, 'source')),
      stability: _stability(_string(value, 'stability')),
    );

OrderedTextUpdateEvent _orderedTextUpdateEvent(Map<String, Object?> value) =>
    OrderedTextUpdateEvent(
      utteranceId: _string(value, 'utteranceId'),
      revision: _int(value, 'revision'),
      text: _string(value, 'text'),
      stability: _stability(_string(value, 'stability')),
    );

OrderedTextUpdateResult _orderedTextUpdateResult(Map<String, Object?> value) =>
    OrderedTextUpdateResult(
      accepted: value['accepted']! as bool,
      reason: _enum(OrderedTextUpdateReason.values, _string(value, 'reason')),
      output: value['output'] == null
          ? null
          : _formattedTextUpdate(_map(value['output'])),
    );

TextRange _range(Map<String, Object?> value) =>
    TextRange(_int(value, 'start'), _int(value, 'length'));

TextSelection _selection(Map<String, Object?> value) =>
    TextSelection(_int(value, 'anchor'), _int(value, 'focus'));

bool _samePlan(EditPlan left, EditPlan right) =>
    left.decision == right.decision &&
    left.resultText == right.resultText &&
    left.selection == right.selection &&
    _sameList(left.insertions, right.insertions);

bool _sameList<T>(List<T> left, List<T> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

T _enum<T extends Enum>(Iterable<T> values, String name) =>
    values.firstWhere((value) => value.name == name);

T? _nullableEnum<T extends Enum>(Iterable<T> values, String? name) =>
    name == null ? null : _enum(values, name);

TextStability _stability(String value) => value == 'final'
    ? TextStability.finalValue
    : _enum(TextStability.values, value);

Map<String, Object?> _map(Object? value) =>
    (value! as Map).cast<String, Object?>();

List<Object?> _list(Map<String, Object?> value, String property) =>
    value[property]! as List<Object?>;

String _string(Map<String, Object?> value, String property) =>
    value[property]! as String;

int _int(Map<String, Object?> value, String property) =>
    value[property]! as int;

void _require(bool condition, String message) {
  if (!condition) throw StateError(message);
}
