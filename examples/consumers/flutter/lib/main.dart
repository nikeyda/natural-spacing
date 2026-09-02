import 'package:flutter/material.dart';
import 'package:natural_spacing/natural_spacing.dart' as core;
import 'package:natural_spacing_flutter/natural_spacing_flutter.dart';

void main() => runApp(const NaturalSpacingConsumerApp());

class NaturalSpacingConsumerApp extends StatelessWidget {
  const NaturalSpacingConsumerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final policy = core.NaturalSpacingPolicy.resolve(
      const core.PolicyContext(contentKind: core.ContentKind.message),
    );

    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 320,
            child: TextField(
              autofocus: true,
              inputFormatters: [
                NaturalSpacingTextInputFormatter(policy: policy),
              ],
              decoration: const InputDecoration(
                labelText: 'Natural-language text',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
