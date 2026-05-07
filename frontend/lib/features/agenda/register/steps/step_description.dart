import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../konecta_tokens.dart';
import '../widgets/step_scaffold.dart';
import '../widgets/summary_card.dart';

class StepDescription extends StatefulWidget {
  const StepDescription({
    super.key,
    required this.value,
    required this.onChanged,
    required this.summaryName,
    required this.summaryDepartment,
    required this.summaryLocality,
    required this.summaryCategory,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String? summaryName;
  final String? summaryDepartment;
  final String? summaryLocality;
  final String? summaryCategory;

  @override
  State<StepDescription> createState() => _StepDescriptionState();
}

class _StepDescriptionState extends State<StepDescription> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
    _ctrl.selection =
        TextSelection.collapsed(offset: _ctrl.text.length);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final underlineSide =
        const BorderSide(color: KTokens.accent, width: 1.5);
    final underlineBorder =
        UnderlineInputBorder(borderSide: underlineSide);

    return StepScaffold(
      eyebrow: 'PASO 05 — DESCRIPCIÓN',
      question: 'Contanos en una frase\nqué hacés.',
      hint: 'Opcional. Máximo 200 caracteres.',
      input: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _ctrl,
            autofocus: true,
            maxLength: 200,
            maxLines: 5,
            minLines: 3,
            onChanged: widget.onChanged,
            cursorColor: KTokens.accent,
            cursorWidth: 2,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.1,
              color: KTokens.ink,
            ),
            buildCounter: (context,
                {required currentLength,
                required isFocused,
                required maxLength}) {
              return Text(
                '$currentLength / $maxLength',
                style: KTokens.tMonoHint,
              );
            },
            decoration: InputDecoration(
              hintText: 'Ej: Cortes y coloración para toda la familia…',
              hintStyle: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.1,
                color: KTokens.inkPlaceholder,
              ),
              border: underlineBorder,
              enabledBorder: underlineBorder,
              focusedBorder: underlineBorder,
              contentPadding: const EdgeInsets.only(bottom: 8),
              isDense: true,
            ),
          ),
        ],
      ),
      summary: SummaryCard(
        rows: [
          SummaryRow(label: 'Negocio', value: widget.summaryName),
          SummaryRow(label: 'Departamento', value: widget.summaryDepartment),
          SummaryRow(label: 'Localidad', value: widget.summaryLocality),
          SummaryRow(label: 'Categoría', value: widget.summaryCategory, skipped: widget.summaryCategory == null),
          const SummaryRow(label: 'Descripción', current: true),
        ],
      ),
    );
  }
}
