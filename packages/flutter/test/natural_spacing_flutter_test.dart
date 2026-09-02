import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_spacing/natural_spacing.dart' as core;
import 'package:natural_spacing_flutter/natural_spacing_flutter.dart';

void main() {
  test('default policy preserves the native edit', () {
    final formatter = NaturalSpacingTextInputFormatter();
    const oldValue = TextEditingValue(text: '中');
    const newValue = TextEditingValue(
      text: '中A',
      selection: TextSelection.collapsed(offset: 2),
    );

    expect(formatter.formatEditUpdate(oldValue, newValue), same(newValue));
  });

  test('natural-language edit inserts a space and maps the caret', () {
    final formatter = NaturalSpacingTextInputFormatter(
      policy: core.FieldPolicy.naturalLanguage,
    );
    const oldValue = TextEditingValue(text: '中');
    const newValue = TextEditingValue(
      text: '中A',
      selection: TextSelection.collapsed(offset: 2),
    );

    final result = formatter.formatEditUpdate(oldValue, newValue);

    expect(result.text, '中 A');
    expect(result.selection, const TextSelection.collapsed(offset: 3));
    expect(result.composing, TextRange.empty);
  });

  test('active composition is returned unchanged', () {
    final formatter = NaturalSpacingTextInputFormatter(
      policy: core.FieldPolicy.naturalLanguage,
    );
    const oldValue = TextEditingValue(text: '中');
    const composingValue = TextEditingValue(
      text: '中A',
      selection: TextSelection.collapsed(offset: 2),
      composing: TextRange(start: 1, end: 2),
    );

    expect(
      formatter.formatEditUpdate(oldValue, composingValue),
      same(composingValue),
    );
  });

  test('settled composition is reconciled after the range collapses', () {
    final formatter = NaturalSpacingTextInputFormatter(
      policy: core.FieldPolicy.naturalLanguage,
    );
    const oldValue = TextEditingValue(text: '中');
    const settledValue = TextEditingValue(
      text: '中A',
      selection: TextSelection.collapsed(offset: 2),
    );

    expect(formatter.formatEditUpdate(oldValue, settledValue).text, '中 A');
  });

  test('selection direction and affinity survive insertion mapping', () {
    final formatter = NaturalSpacingTextInputFormatter(
      policy: core.FieldPolicy.naturalLanguage,
    );
    const newValue = TextEditingValue(
      text: '中A',
      selection: TextSelection(
        baseOffset: 2,
        extentOffset: 1,
        affinity: TextAffinity.upstream,
        isDirectional: true,
      ),
    );

    final result = formatter.formatEditUpdate(
      const TextEditingValue(text: '中'),
      newValue,
    );

    expect(result.text, '中 A');
    expect(
      result.selection,
      const TextSelection(
        baseOffset: 3,
        extentOffset: 2,
        affinity: TextAffinity.upstream,
        isDirectional: true,
      ),
    );
  });

  test('manual deletion suppresses reinsertion for the same boundary', () {
    final formatter = NaturalSpacingTextInputFormatter(
      policy: core.FieldPolicy.naturalLanguage,
    );
    const spaced = TextEditingValue(
      text: '中 A',
      selection: TextSelection.collapsed(offset: 3),
    );
    const deleted = TextEditingValue(
      text: '中A',
      selection: TextSelection.collapsed(offset: 1),
    );

    expect(formatter.formatEditUpdate(spaced, deleted), same(deleted));

    const continued = TextEditingValue(
      text: '中AB',
      selection: TextSelection.collapsed(offset: 3),
    );
    expect(formatter.formatEditUpdate(deleted, continued).text, '中AB');
  });

  test('reset clears remembered deletion intent', () {
    final formatter = NaturalSpacingTextInputFormatter(
      policy: core.FieldPolicy.naturalLanguage,
    );
    const spaced = TextEditingValue(text: '中 A');
    const deleted = TextEditingValue(text: '中A');
    formatter.formatEditUpdate(spaced, deleted);

    formatter.reset();

    final result = formatter.formatEditUpdate(
      const TextEditingValue(text: '中'),
      const TextEditingValue(text: '中A'),
    );
    expect(result.text, '中 A');
  });

  test('length limit fails open instead of exceeding the contract', () {
    final formatter = NaturalSpacingTextInputFormatter(
      policy: core.FieldPolicy.naturalLanguage,
      maxLengthUtf16: 2,
    );
    const oldValue = TextEditingValue(text: '中');
    const newValue = TextEditingValue(
      text: '中A',
      selection: TextSelection.collapsed(offset: 2),
    );

    expect(formatter.formatEditUpdate(oldValue, newValue), same(newValue));
  });

  test('paste-like replacement scans fragment and outer boundaries', () {
    final formatter = NaturalSpacingTextInputFormatter(
      policy: core.FieldPolicy.naturalLanguage,
    );
    const oldValue = TextEditingValue(text: '中文');
    const newValue = TextEditingValue(
      text: '中A1文',
      selection: TextSelection.collapsed(offset: 3),
    );

    final result = formatter.formatEditUpdate(oldValue, newValue);

    expect(result.text, '中 A1 文');
    expect(result.selection, const TextSelection.collapsed(offset: 5));
  });

  testWidgets('TextField applies spacing to simulated platform input', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final formatter = NaturalSpacingTextInputFormatter(
      policy: core.FieldPolicy.naturalLanguage,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: TextField(
            controller: controller,
            inputFormatters: [formatter],
          ),
        ),
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.showKeyboard(find.byType(TextField));

    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '中2',
        selection: TextSelection.collapsed(offset: 2),
      ),
    );
    await tester.pump();

    expect(controller.text, '中 2');
    expect(controller.selection, const TextSelection.collapsed(offset: 3));
  });

  testWidgets('controller synchronization clears prior deletion intent', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final formatter = NaturalSpacingTextInputFormatter(
      policy: core.FieldPolicy.naturalLanguage,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: TextField(
            controller: controller,
            inputFormatters: [formatter],
          ),
        ),
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.showKeyboard(find.byType(TextField));

    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '中A',
        selection: TextSelection.collapsed(offset: 2),
      ),
    );
    await tester.pump();
    expect(controller.text, '中 A');

    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '中A',
        selection: TextSelection.collapsed(offset: 1),
      ),
    );
    await tester.pump();
    expect(controller.text, '中A');

    controller.value = const TextEditingValue(
      text: '中',
      selection: TextSelection.collapsed(offset: 1),
    );
    formatter.sync();
    await tester.pump();

    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '中A',
        selection: TextSelection.collapsed(offset: 2),
      ),
    );
    await tester.pump();

    expect(controller.text, '中 A');
    expect(controller.selection, const TextSelection.collapsed(offset: 3));
  });
}
