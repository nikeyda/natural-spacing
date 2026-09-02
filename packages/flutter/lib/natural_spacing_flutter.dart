library;

import 'package:flutter/services.dart';
import 'package:natural_spacing/natural_spacing.dart' as core;

/// Experimental formatter for Flutter plain-text fields.
///
/// The formatter returns composing values unchanged and only reconciles a
/// settled edit after [TextEditingValue.composing] has collapsed.
final class NaturalSpacingTextInputFormatter extends TextInputFormatter {
  NaturalSpacingTextInputFormatter({
    this.policy = core.FieldPolicy.verbatim,
    this.maxLengthUtf16,
  });

  final core.FieldPolicy policy;
  final int? maxLengthUtf16;
  final core.NaturalSpacingSession _session = core.NaturalSpacingSession();

  /// Clears remembered manual auto-space deletions.
  void reset() => _session.reset();

  /// Synchronizes after an owning controller replaces the field value.
  ///
  /// The formatter receives the controller's actual value as `oldValue` on the
  /// next platform edit, so synchronization only needs to clear editor intent.
  void sync() => _session.reset();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!newValue.composing.isCollapsed) return newValue;

    final proposed = core.NaturalSpacing.replacingDifference(
      beforeText: oldValue.text,
      afterText: newValue.text,
      policy: policy,
      selectionAfterEdit: core.TextSelection(
        newValue.selection.baseOffset,
        newValue.selection.extentOffset,
      ),
      maxLengthUtf16: maxLengthUtf16,
    );
    if (proposed == null) return newValue;

    final result = _session.processProposedEdit(proposed);
    if (!result.requiresReplacement) return newValue;

    return TextEditingValue(
      text: result.plan.resultText,
      selection: TextSelection(
        baseOffset: result.plan.selection.anchor,
        extentOffset: result.plan.selection.focus,
        affinity: newValue.selection.affinity,
        isDirectional: newValue.selection.isDirectional,
      ),
      composing: TextRange.empty,
    );
  }
}
