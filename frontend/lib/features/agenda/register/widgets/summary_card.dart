import 'package:flutter/material.dart';

import '../konecta_tokens.dart';

class SummaryRow {
  const SummaryRow({
    required this.label,
    this.value,
    this.current = false,
    this.skipped = false,
  });

  final String label;
  final String? value;
  final bool current;
  final bool skipped;
}

class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key, required this.rows});

  final List<SummaryRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: KTokens.surface,
        borderRadius: BorderRadius.circular(KTokens.rSm),
        border: Border.all(color: KTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HASTA AHORA',
            style: KTokens.tMonoHint.copyWith(letterSpacing: 1.2),
          ),
          const SizedBox(height: 10),
          ...rows.map((row) => _SummaryRowWidget(row: row)),
        ],
      ),
    );
  }
}

class _SummaryRowWidget extends StatelessWidget {
  const _SummaryRowWidget({required this.row});

  final SummaryRow row;

  @override
  Widget build(BuildContext context) {
    Widget valueWidget;

    if (row.current) {
      valueWidget = Text(
        'completando…',
        style: KTokens.tSummaryLabel.copyWith(
          color: KTokens.inkPlaceholder,
          fontStyle: FontStyle.italic,
        ),
      );
    } else if (row.skipped || row.value == null) {
      valueWidget = Text('—', style: KTokens.tMonoHint);
    } else {
      valueWidget = Text(row.value!, style: KTokens.tSummaryValue);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(row.label, style: KTokens.tSummaryLabel),
          const SizedBox(width: 12),
          Flexible(
            child: valueWidget,
          ),
        ],
      ),
    );
  }
}
