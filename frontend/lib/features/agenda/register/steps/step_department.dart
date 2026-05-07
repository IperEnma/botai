import 'package:flutter/material.dart';

import '../konecta_tokens.dart';
import '../widgets/conversational_input.dart';
import '../widgets/step_scaffold.dart';
import '../widgets/summary_card.dart';

const _kDepts = [
  'Artigas', 'Canelones', 'Cerro Largo', 'Colonia', 'Durazno',
  'Flores', 'Florida', 'Lavalleja', 'Maldonado', 'Montevideo',
  'Paysandú', 'Río Negro', 'Rivera', 'Rocha', 'Salto',
  'San José', 'Soriano', 'Tacuarembó', 'Treinta y Tres',
];

class StepDepartment extends StatefulWidget {
  const StepDepartment({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onSubmitted,
    required this.showError,
    this.summaryName,
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final VoidCallback onSubmitted;
  final bool showError;
  final String? summaryName;

  @override
  State<StepDepartment> createState() => _StepDepartmentState();
}

class _StepDepartmentState extends State<StepDepartment> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;
  List<String> _suggestions = [];
  bool _showSuggestions = false;
  String? _tappingItem;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value ?? '');
    _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
    _focus = FocusNode();

    _focus.addListener(() {
      if (!_focus.hasFocus) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && _tappingItem == null) {
            setState(() => _showSuggestions = false);
          }
        });
      } else {
        _updateSuggestions(_ctrl.text);
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _updateSuggestions(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) {
      setState(() {
        _suggestions = _kDepts;
        _showSuggestions = _focus.hasFocus;
      });
      return;
    }
    final filtered = _kDepts
        .where((d) => d.toLowerCase().contains(q))
        .toList();
    setState(() {
      _suggestions = filtered;
      _showSuggestions = filtered.isNotEmpty && _focus.hasFocus;
    });
  }

  void _selectDept(String dept) {
    _tappingItem = dept;
    _ctrl.text = dept;
    _ctrl.selection = TextSelection.collapsed(offset: dept.length);
    setState(() => _showSuggestions = false);
    widget.onChanged(dept);
    _tappingItem = null;
    widget.onSubmitted();
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      eyebrow: 'PASO 02 — DIRECCIÓN',
      question: '¿En qué departamento\nestás?',
      hint: 'Escribí las primeras letras y elegí de la lista.',
      input: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConversationalInput(
            controller: _ctrl,
            focusNode: _focus,
            hintText: 'Ej: Montevideo, Canelones…',
            metaLeft: 'departamento',
            autofocus: true,
            onChanged: (v) {
              _updateSuggestions(v);
              if (!_kDepts.any((d) => d.toLowerCase() == v.toLowerCase())) {
                widget.onChanged(null);
              } else {
                widget.onChanged(v);
              }
            },
            onSubmitted: (_) => widget.onSubmitted(),
            showError: widget.showError,
            errorText: 'Elegí un departamento',
          ),
          if (_showSuggestions && _suggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              constraints: const BoxConstraints(maxHeight: 130),
              decoration: BoxDecoration(
                color: KTokens.surface,
                borderRadius: BorderRadius.circular(KTokens.rMd),
                border: Border.all(color: KTokens.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _suggestions.map((dept) {
                    final isSelected = dept == widget.value;
                    return GestureDetector(
                      onTapDown: (_) {
                        _tappingItem = dept;
                        _selectDept(dept);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        color: isSelected
                            ? KTokens.accentSoft
                            : Colors.transparent,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                dept,
                                style: KTokens.tInput.copyWith(
                                  fontSize: 15,
                                  color: isSelected
                                      ? KTokens.accent
                                      : KTokens.ink,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check,
                                  size: 16, color: KTokens.accent),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
      summary: SummaryCard(
        rows: [
          SummaryRow(label: 'Negocio', value: widget.summaryName),
          const SummaryRow(label: 'Departamento', current: true),
        ],
      ),
    );
  }
}
