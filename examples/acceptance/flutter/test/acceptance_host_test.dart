import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_spacing_flutter_acceptance/main.dart';

void main() {
  testWidgets('natural-language and secure fields keep distinct policies', (
    tester,
  ) async {
    await tester.pumpWidget(const NaturalSpacingFlutterAcceptanceApp());

    final natural = find.byKey(const Key('natural-field'));
    await tester.tap(natural);
    await tester.showKeyboard(natural);
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '中A',
        selection: TextSelection.collapsed(offset: 2),
      ),
    );
    await tester.pump();

    final naturalWidget = tester.widget<TextField>(natural);
    expect(naturalWidget.controller!.text, '中 A');

    final secure = find.byKey(const Key('secure-field'));
    await tester.tap(secure);
    await tester.showKeyboard(secure);
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '口令A2',
        selection: TextSelection.collapsed(offset: 4),
      ),
    );
    await tester.pump();

    final secureWidget = tester.widget<TextField>(secure);
    expect(secureWidget.controller!.text, '口令A2');
    final secureDiagnostics = tester.widget<SelectableText>(
      find.descendant(
        of: find.byKey(const Key('secure-diagnostics')),
        matching: find.byType(SelectableText),
      ),
    );
    expect(secureDiagnostics.data, contains('text=<hidden>'));
    expect(secureDiagnostics.data, isNot(contains('口令A2')));
  });
}
