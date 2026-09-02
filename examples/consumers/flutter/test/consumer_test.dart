import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_spacing/natural_spacing.dart' as core;
import 'package:natural_spacing_flutter/natural_spacing_flutter.dart';
import 'package:natural_spacing_flutter_consumer/main.dart';

void main() {
  test('consumer can apply natural-language spacing', () {
    final formatter = NaturalSpacingTextInputFormatter(
      policy: core.FieldPolicy.naturalLanguage,
    );

    final result = formatter.formatEditUpdate(
      const TextEditingValue(text: '中'),
      const TextEditingValue(
        text: '中A',
        selection: TextSelection.collapsed(offset: 2),
      ),
    );

    expect(result.text, '中 A');
    expect(result.selection, const TextSelection.collapsed(offset: 3));
  });

  test('consumer gets a safe default formatter', () {
    final formatter = NaturalSpacingTextInputFormatter();
    const oldValue = TextEditingValue(text: '中');
    const newValue = TextEditingValue(text: '中A');

    expect(formatter.formatEditUpdate(oldValue, newValue), same(newValue));
    expect(
      core.NaturalSpacingPolicy.resolve(
        const core.PolicyContext(
          explicitPolicy: core.FieldPolicy.naturalLanguage,
          contentKind: core.ContentKind.message,
          isSecure: true,
        ),
      ),
      core.FieldPolicy.verbatim,
    );
  });

  test('consumer coordinates ordered ASR revisions through the Dart core', () {
    final session = core.OrderedTextUpdateSession();
    expect(session.start('utterance-1'), isTrue);

    final result = session.accept(
      const core.OrderedTextUpdateEvent(
        utteranceId: 'utterance-1',
        revision: 0,
        text: '中2文',
        stability: core.TextStability.finalValue,
      ),
    );

    expect(result.output?.committedText, '中 2 文');
  });

  testWidgets('consumer app resolves policy and wires a TextField', (
    tester,
  ) async {
    await tester.pumpWidget(const NaturalSpacingConsumerApp());

    final textField = find.byType(TextField);
    expect(textField, findsOneWidget);
    await tester.enterText(textField, '中A');

    expect(find.text('中 A'), findsOneWidget);
  });
}
