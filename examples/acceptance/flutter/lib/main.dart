import 'package:flutter/material.dart';
import 'package:natural_spacing/natural_spacing.dart' as core;
import 'package:natural_spacing_flutter/natural_spacing_flutter.dart';

void main() => runApp(const NaturalSpacingFlutterAcceptanceApp());

class NaturalSpacingFlutterAcceptanceApp extends StatelessWidget {
  const NaturalSpacingFlutterAcceptanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AcceptanceHome(),
    );
  }
}

class AcceptanceHome extends StatefulWidget {
  const AcceptanceHome({super.key});

  @override
  State<AcceptanceHome> createState() => _AcceptanceHomeState();
}

class _AcceptanceHomeState extends State<AcceptanceHome> {
  static final _naturalPolicy = core.NaturalSpacingPolicy.resolve(
    const core.PolicyContext(contentKind: core.ContentKind.message),
  );
  static final _securePolicy = core.NaturalSpacingPolicy.resolve(
    const core.PolicyContext(
      explicitPolicy: core.FieldPolicy.naturalLanguage,
      contentKind: core.ContentKind.password,
      isSecure: true,
    ),
  );

  final _naturalController = TextEditingController();
  final _secureController = TextEditingController();
  late final NaturalSpacingTextInputFormatter _naturalFormatter;
  late final NaturalSpacingTextInputFormatter _secureFormatter;

  @override
  void initState() {
    super.initState();
    _naturalFormatter = NaturalSpacingTextInputFormatter(
      policy: _naturalPolicy,
    );
    _secureFormatter = NaturalSpacingTextInputFormatter(policy: _securePolicy);
    _naturalController.addListener(_refreshDiagnostics);
    _secureController.addListener(_refreshDiagnostics);
  }

  @override
  void dispose() {
    _naturalController
      ..removeListener(_refreshDiagnostics)
      ..dispose();
    _secureController
      ..removeListener(_refreshDiagnostics)
      ..dispose();
    super.dispose();
  }

  void _refreshDiagnostics() {
    if (mounted) setState(() {});
  }

  void _reset() {
    _naturalController.clear();
    _secureController.clear();
    _naturalFormatter.sync();
    _secureFormatter.sync();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Natural Spacing acceptance')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Use synthetic text only. Exercise composition, selection, '
              'paste, deletion, undo, dictation, hardware keyboards, and '
              'accessibility input separately.',
            ),
            const SizedBox(height: 24),
            TextField(
              key: const Key('natural-field'),
              controller: _naturalController,
              autofocus: true,
              inputFormatters: [_naturalFormatter],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Message · naturalLanguage',
                hintText: 'Example: 中文A2',
              ),
            ),
            const SizedBox(height: 8),
            _Diagnostics(
              key: const Key('natural-diagnostics'),
              value: _naturalController.value,
              policy: _naturalPolicy,
              hideText: false,
            ),
            const SizedBox(height: 24),
            TextField(
              key: const Key('secure-field'),
              controller: _secureController,
              inputFormatters: [_secureFormatter],
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Password · forced verbatim',
              ),
            ),
            const SizedBox(height: 8),
            _Diagnostics(
              key: const Key('secure-diagnostics'),
              value: _secureController.value,
              policy: _securePolicy,
              hideText: true,
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                key: const Key('reset-button'),
                onPressed: _reset,
                child: const Text('Reset session'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Diagnostics extends StatelessWidget {
  const _Diagnostics({
    super.key,
    required this.value,
    required this.policy,
    required this.hideText,
  });

  final TextEditingValue value;
  final core.FieldPolicy policy;
  final bool hideText;

  @override
  Widget build(BuildContext context) {
    final text = hideText ? '<hidden>' : value.text;
    return SelectableText(
      'policy=${policy.name}\n'
      'text=$text\n'
      'selection=${_range(value.selection)}\n'
      'composing=${_range(value.composing)}',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }

  static String _range(TextRange range) {
    if (!range.isValid) return 'invalid';
    return '${range.start}..${range.end}';
  }
}
