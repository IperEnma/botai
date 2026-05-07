import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../konecta_tokens.dart';
import '../widgets/conversational_input.dart';
import '../widgets/step_scaffold.dart';
import '../widgets/summary_card.dart';

class StepLocality extends StatefulWidget {
  const StepLocality({
    super.key,
    required this.department,
    required this.value,
    required this.onChanged,
    required this.streetAddress,
    required this.onStreetChanged,
    required this.onSubmitted,
    required this.showError,
    this.summaryName,
    this.summaryDepartment,
  });

  final String? department;
  final String value;
  final ValueChanged<String> onChanged;
  final String streetAddress;
  final ValueChanged<String> onStreetChanged;
  final VoidCallback onSubmitted;
  final bool showError;
  final String? summaryName;
  final String? summaryDepartment;

  @override
  State<StepLocality> createState() => _StepLocalityState();
}

class _StepLocalityState extends State<StepLocality> {
  late final TextEditingController _localCtrl;
  late final TextEditingController _streetCtrl;

  @override
  void initState() {
    super.initState();
    _localCtrl = TextEditingController(text: widget.value);
    _localCtrl.selection =
        TextSelection.collapsed(offset: _localCtrl.text.length);
    _localCtrl.addListener(_onLocalChanged);
    _streetCtrl = TextEditingController(text: widget.streetAddress);
    _streetCtrl.selection =
        TextSelection.collapsed(offset: _streetCtrl.text.length);
  }

  void _onLocalChanged() => setState(() {});

  @override
  void dispose() {
    _localCtrl.removeListener(_onLocalChanged);
    _localCtrl.dispose();
    _streetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dept = widget.department ?? 'tu departamento';
    final hasLocality = _localCtrl.text.trim().isNotEmpty;

    return StepScaffold(
      eyebrow: 'PASO 03 — DIRECCIÓN',
      question: '¿En qué localidad\nestás?',
      hint: 'Localidad dentro de $dept.',
      input: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConversationalInput(
            controller: _localCtrl,
            hintText: 'Ej: Montevideo, Punta del Este…',
            metaLeft: 'localidad',
            onChanged: widget.onChanged,
            onSubmitted: (_) => widget.onSubmitted(),
            showError: widget.showError,
            errorText: 'Ingresá la localidad',
          ),
          if (hasLocality) ...[
            const SizedBox(height: 28),
            Text(
              '¿Agregás la dirección exacta? (opcional)',
              style: KTokens.tHint,
            ),
            const SizedBox(height: 12),
            _StreetField(
              controller: _streetCtrl,
              onChanged: widget.onStreetChanged,
              onSubmitted: (_) => widget.onSubmitted(),
            ),
          ],
        ],
      ),
      summary: SummaryCard(
        rows: [
          SummaryRow(label: 'Negocio', value: widget.summaryName),
          SummaryRow(label: 'Departamento', value: widget.summaryDepartment),
          const SummaryRow(label: 'Localidad', current: true),
        ],
      ),
    );
  }
}

class _StreetField extends StatelessWidget {
  const _StreetField({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  static TextStyle get _inputStyle => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.1,
        color: KTokens.ink,
      );

  @override
  Widget build(BuildContext context) {
    const underlineSide = BorderSide(color: KTokens.accent, width: 1.5);
    const underlineBorder = UnderlineInputBorder(borderSide: underlineSide);

    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: _inputStyle,
      cursorColor: KTokens.accent,
      cursorWidth: 2,
      decoration: InputDecoration(
        hintText: 'Calle y número',
        hintStyle: _inputStyle.copyWith(color: KTokens.inkPlaceholder),
        border: underlineBorder,
        enabledBorder: underlineBorder,
        focusedBorder: underlineBorder,
        contentPadding: const EdgeInsets.only(bottom: 8),
        isDense: true,
      ),
    );
  }
}
