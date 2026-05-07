import 'package:flutter/material.dart';

import '../konecta_tokens.dart';

class StepScaffold extends StatelessWidget {
  const StepScaffold({
    super.key,
    required this.eyebrow,
    required this.question,
    this.hint,
    required this.input,
    this.summary,
  });

  final String eyebrow;
  final String question;
  final String? hint;
  final Widget input;
  final Widget? summary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(eyebrow, style: KTokens.tEyebrow),
                    const SizedBox(height: 14),
                    Text(question, style: KTokens.tQuestion),
                    if (hint != null) ...[
                      const SizedBox(height: 10),
                      Text(hint!, style: KTokens.tHint),
                    ],
                    const SizedBox(height: 36),
                    input,
                    if (summary != null) ...[
                      const Spacer(),
                      summary!,
                      const SizedBox(height: 24),
                    ] else
                      const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
