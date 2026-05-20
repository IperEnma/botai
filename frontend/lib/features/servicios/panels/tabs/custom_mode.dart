import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/agenda/staff_member.dart';
import '../../../agenda/register/konecta_tokens.dart';
import '../../data/service_group_catalog.dart';
import '../../models/business_category.dart';
import '../../models/servicio_item.dart';

// ─── Public form data ─────────────────────────────────────────────────────────

class CustomFormData {
  final String name;
  final String description;
  final String? groupId;
  final int durationMinutes;
  final bool flexibleDuration;
  final int priceUyu;
  final bool priceFrom;
  final List<String> professionalIds;

  const CustomFormData({
    required this.name,
    required this.description,
    required this.groupId,
    required this.durationMinutes,
    required this.flexibleDuration,
    required this.priceUyu,
    required this.priceFrom,
    required this.professionalIds,
  });

  bool get isValid => name.trim().isNotEmpty && groupId != null;
}

// ─── Widget ───────────────────────────────────────────────────────────────────

class CustomMode extends StatefulWidget {
  const CustomMode({
    super.key,
    required this.category,
    required this.staff,
    required this.extraGroupNames,
    this.initial,
    this.prefillGroupId,
    required this.onChanged,
  });

  final BusinessCategory category;
  final List<StaffMember> staff;
  final List<String> extraGroupNames;
  final ServicioItem? initial;
  final String? prefillGroupId;
  final ValueChanged<CustomFormData> onChanged;

  @override
  State<CustomMode> createState() => _CustomModeState();
}

class _CustomModeState extends State<CustomMode> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _durCtrl = TextEditingController(text: '60');
  final _priceCtrl = TextEditingController(text: '0');

  final _durFocus = FocusNode();
  final _priceFocus = FocusNode();
  final _descFocus = FocusNode();

  String? _selectedGroupId;
  bool _flexibleDuration = false;
  bool _priceFrom = false;
  final Set<String> _selectedPros = {};
  final List<String> _customGroupNames = [];

  @override
  void initState() {
    super.initState();
    _durFocus.addListener(() => setState(() {}));
    _priceFocus.addListener(() => setState(() {}));
    _descFocus.addListener(() => setState(() {}));

    final initial = widget.initial;
    if (initial != null) {
      _nameCtrl.text = initial.name;
      _descCtrl.text = initial.description ?? '';
      _selectedGroupId = initial.groupId;
      _durCtrl.text = initial.durationMinutes.toString();
      _priceCtrl.text = initial.priceUyu.toString();
      _flexibleDuration = initial.flexibleDuration;
      _priceFrom = initial.priceFrom;
      _selectedPros.addAll(initial.professionalIds);
    } else if (widget.prefillGroupId != null) {
      _selectedGroupId = widget.prefillGroupId;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _durCtrl.dispose();
    _priceCtrl.dispose();
    _durFocus.dispose();
    _priceFocus.dispose();
    _descFocus.dispose();
    super.dispose();
  }

  void _notify() {
    widget.onChanged(
      CustomFormData(
        name: _nameCtrl.text,
        description: _descCtrl.text,
        groupId: _selectedGroupId,
        durationMinutes: int.tryParse(_durCtrl.text) ?? 60,
        flexibleDuration: _flexibleDuration,
        priceUyu: int.tryParse(_priceCtrl.text) ?? 0,
        priceFrom: _priceFrom,
        professionalIds: _selectedPros.toList(),
      ),
    );
  }

  void _showNewGroupDialog() {
    final ctrl = TextEditingController();
    showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(
          'Nueva sub-categoría',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: KTokens.ink,
          ),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: GoogleFonts.inter(fontSize: 14, color: KTokens.ink),
          decoration: InputDecoration(
            hintText: 'Nombre de la sub-categoría',
            hintStyle: GoogleFonts.inter(
                fontSize: 14, color: KTokens.inkPlaceholder),
          ),
          onSubmitted: (v) => Navigator.pop(dialogCtx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancelar',
                style: GoogleFonts.inter(color: KTokens.inkMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, ctrl.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: KTokens.accent,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: Text('Crear', style: GoogleFonts.inter()),
          ),
        ],
      ),
    ).then((name) {
      if (name != null && name.trim().isNotEmpty) {
        setState(() {
          _customGroupNames.add(name.trim());
          _selectedGroupId = 'custom_${name.trim()}';
        });
        _notify();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final catalogGroups = ServiceGroupCatalog.forCategory(widget.category);
    final allGroups = [
      ...catalogGroups.map((g) => (id: g.id, name: g.name)),
      ..._customGroupNames.map((n) => (id: 'custom_$n', name: n)),
    ];

    final formData = CustomFormData(
      name: _nameCtrl.text,
      description: _descCtrl.text,
      groupId: _selectedGroupId,
      durationMinutes: int.tryParse(_durCtrl.text) ?? 60,
      flexibleDuration: _flexibleDuration,
      priceUyu: int.tryParse(_priceCtrl.text) ?? 0,
      priceFrom: _priceFrom,
      professionalIds: _selectedPros.toList(),
    );

    final hasNewGroup = _selectedGroupId != null &&
        _selectedGroupId!.startsWith('custom_');
    final newGroupName = hasNewGroup
        ? _selectedGroupId!.replaceFirst('custom_', '')
        : null;
    final selectedGroupName = allGroups
        .where((g) => g.id == _selectedGroupId)
        .map((g) => g.name)
        .firstOrNull;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Nombre
          _EyebrowLabel('NOMBRE DEL SERVICIO'),
          const SizedBox(height: 6),
          TextField(
            controller: _nameCtrl,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: KTokens.ink,
            ),
            decoration: InputDecoration(
              filled: false,
              hintText: 'Ej: Limpieza facial profunda',
              hintStyle: GoogleFonts.inter(
                fontSize: 20,
                color: KTokens.inkPlaceholder,
                fontWeight: FontWeight.w500,
              ),
              border: const UnderlineInputBorder(
                borderSide: BorderSide(color: KTokens.border, width: 1.5),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: KTokens.accent, width: 1.5),
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: KTokens.border, width: 1.5),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
            onChanged: (_) => _notify(),
          ),
          const SizedBox(height: 20),

          // 2. Descripción
          _EyebrowLabel('DESCRIPCIÓN · opcional'),
          const SizedBox(height: 6),
          _DescriptionField(
            controller: _descCtrl,
            focusNode: _descFocus,
            hasFocus: _descFocus.hasFocus,
            onChanged: (_) => _notify(),
          ),
          const SizedBox(height: 20),

          // 3. Sub-categoría
          _EyebrowLabel('SUB-CATEGORÍA'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...allGroups.map((g) {
                final isSelected = _selectedGroupId == g.id;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedGroupId = g.id);
                    _notify();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0x143B2F63)
                          : KTokens.surface,
                      border: Border.all(
                        color: isSelected ? KTokens.accent : KTokens.border,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      g.name,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w500
                            : FontWeight.w400,
                        color: isSelected ? KTokens.accent : KTokens.ink,
                      ),
                    ),
                  ),
                );
              }),
              // Create new group chip
              GestureDetector(
                onTap: _showNewGroupDialog,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: KTokens.surface,
                    border: Border.all(color: KTokens.border),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '+ Crear nueva',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: KTokens.inkMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 4. Duración + Precio
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Duración
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => _durFocus.requestFocus(),
                      child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _durFocus.hasFocus
                              ? KTokens.ink
                              : KTokens.border,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(KTokens.rSm),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DURACIÓN',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              color: KTokens.inkSoft,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              SizedBox(
                                width: 56,
                                child: TextField(
                                  controller: _durCtrl,
                                  focusNode: _durFocus,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  style: GoogleFonts.inter(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: KTokens.ink,
                                  ),
                                  decoration: const InputDecoration(
                                    filled: false,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (_) => _notify(),
                                ),
                              ),
                              Text(
                                ' min',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: KTokens.inkSoft,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ),
                    const SizedBox(height: 8),
                    _CheckRow(
                      label: 'Duración estimada (puede variar)',
                      value: _flexibleDuration,
                      onChanged: (v) {
                        setState(() => _flexibleDuration = v);
                        _notify();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Precio
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => _priceFocus.requestFocus(),
                      child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _priceFocus.hasFocus
                              ? KTokens.ink
                              : KTokens.border,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(KTokens.rSm),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PRECIO',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              color: KTokens.inkSoft,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                'UY \$ ',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: KTokens.inkSoft,
                                ),
                              ),
                              SizedBox(
                                width: 80,
                                child: TextField(
                                  controller: _priceCtrl,
                                  focusNode: _priceFocus,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  style: GoogleFonts.inter(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: KTokens.ink,
                                  ),
                                  decoration: const InputDecoration(
                                    filled: false,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (_) => _notify(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ),
                    const SizedBox(height: 8),
                    _CheckRow(
                      label: 'Mostrar como "desde UY \$X"',
                      value: _priceFrom,
                      onChanged: (v) {
                        setState(() => _priceFrom = v);
                        _notify();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 5. Profesionales
          _EyebrowLabel('QUIÉN LO OFRECE'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.staff.asMap().entries.map((entry) {
              final idx = entry.key;
              final member = entry.value;
              final color = KTokens.proPalette[idx % KTokens.proPalette.length];
              final isSelected = _selectedPros.contains(member.id);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedPros.remove(member.id);
                    } else {
                      _selectedPros.add(member.id);
                    }
                  });
                  _notify();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0x143B2F63)
                        : KTokens.surface,
                    border: Border.all(
                      color: isSelected ? KTokens.accent : KTokens.border,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        member.nombre,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w500
                              : FontWeight.w400,
                          color: isSelected ? KTokens.accent : KTokens.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // 6. Summary box
          _SummaryBox(
            formData: formData,
            hasNewGroup: hasNewGroup,
            newGroupName: newGroupName,
            selectedGroupName: selectedGroupName,
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _EyebrowLabel extends StatelessWidget {
  const _EyebrowLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.jetBrainsMono(
        fontSize: 10,
        letterSpacing: 1.4,
        color: KTokens.inkSoft,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _DescriptionField extends StatefulWidget {
  const _DescriptionField({
    required this.controller,
    required this.focusNode,
    required this.hasFocus,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasFocus;
  final ValueChanged<String> onChanged;

  @override
  State<_DescriptionField> createState() => _DescriptionFieldState();
}

class _DescriptionFieldState extends State<_DescriptionField> {
  static const _maxChars = 200;

  @override
  Widget build(BuildContext context) {
    final count = widget.controller.text.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: () => widget.focusNode.requestFocus(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: widget.hasFocus ? KTokens.ink : KTokens.border,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(KTokens.rSm),
            ),
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              maxLines: null,
              minLines: 3,
              maxLength: _maxChars,
              buildCounter:
                  (_, {required currentLength, required isFocused, maxLength}) =>
                      null,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: KTokens.inkSoft,
                height: 1.5,
              ),
              decoration: InputDecoration(
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: 'Descripción opcional visible para el cliente…',
                hintStyle: GoogleFonts.inter(
                    fontSize: 13, color: KTokens.inkPlaceholder),
              ),
              onChanged: (v) {
                setState(() {});
                widget.onChanged(v);
              },
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$count/$_maxChars',
          style: GoogleFonts.inter(fontSize: 11, color: KTokens.inkMuted),
        ),
      ],
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: value,
            onChanged: (v) => onChanged(v ?? false),
            activeColor: KTokens.accent,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 13, color: KTokens.ink),
          ),
        ),
      ],
    );
  }
}

class _SummaryBox extends StatelessWidget {
  const _SummaryBox({
    required this.formData,
    required this.hasNewGroup,
    required this.newGroupName,
    required this.selectedGroupName,
  });

  final CustomFormData formData;
  final bool hasNewGroup;
  final String? newGroupName;
  final String? selectedGroupName;

  @override
  Widget build(BuildContext context) {
    final lines = <String>[];
    lines.add('AL CREAR · APARECE COMO OPCIÓN EN /TU-NEGOCIO');
    if (hasNewGroup && newGroupName != null) {
      lines.add('SUB-CATEGORÍA NUEVA: ${newGroupName!.toUpperCase()}');
    }
    if (formData.professionalIds.isEmpty) {
      lines.add('ASIGNÁ PROFESIONALES DESPUÉS EN /EQUIPO');
    } else {
      final count = formData.professionalIds.length;
      lines.add(
          '$count PROFESIONAL${count > 1 ? 'ES' : ''} PUEDE${count > 1 ? 'N' : ''} ATENDERLO');
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: KTokens.accentSoft,
        border: Border.all(color: const Color(0x263B2F63)),
        borderRadius: BorderRadius.circular(KTokens.rSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines
            .map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  line,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    letterSpacing: 1.4,
                    color: KTokens.accent,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
