import 'package:flutter/material.dart';

import '../widgets/conversational_input.dart';
import '../widgets/step_scaffold.dart';
import '../widgets/summary_card.dart';

class StepName extends StatefulWidget {
  const StepName({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onSubmitted,
    required this.showError,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
  final bool showError;

  @override
  State<StepName> createState() => _StepNameState();
}

class _StepNameState extends State<StepName> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
    _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      eyebrow: 'PASO 01 — NEGOCIO',
      question: '¿Cómo se llama\ntu negocio?',
      hint: 'Puede ser el nombre de tu local, tu nombre profesional o tu marca.',
      input: ConversationalInput(
        controller: _ctrl,
        hintText: 'Ej: Estudio Norte, Ana López…',
        metaLeft: 'nombre del negocio o profesión',
        onChanged: widget.onChanged,
        onSubmitted: (_) => widget.onSubmitted(),
        showError: widget.showError,
        errorText: 'Este dato es obligatorio',
      ),
      summary: const SummaryCard(
        rows: [SummaryRow(label: 'Negocio', current: true)],
      ),
    );
  }
}
