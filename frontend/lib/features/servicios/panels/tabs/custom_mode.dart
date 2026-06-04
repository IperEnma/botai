import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/agenda/service_scheduling_mode.dart';
import '../../../../models/agenda/staff_member.dart';
import '../../../agenda/equipo/widgets/add_member_panel.dart';
import '../../../agenda/register/konecta_tokens.dart';
import '../../controllers/servicios_controller.dart';
import '../../models/servicio_item.dart';

// ─── Public form data ─────────────────────────────────────────────────────────

class CustomFormData {
  final String name;
  final String description;
  final int durationMinutes;
  final bool flexibleDuration;
  final int priceUyu;
  final bool priceFrom;
  final ServiceSchedulingMode schedulingMode;
  final List<String> professionalIds;

  const CustomFormData({
    required this.name,
    required this.description,
    required this.durationMinutes,
    required this.flexibleDuration,
    required this.priceUyu,
    required this.priceFrom,
    required this.schedulingMode,
    required this.professionalIds,
  });

  bool get isValid => name.trim().isNotEmpty;
  bool get usesStaff => schedulingMode == ServiceSchedulingMode.byStaff;
}

// ─── Widget ───────────────────────────────────────────────────────────────────

class CustomMode extends StatefulWidget {
  const CustomMode({
    super.key,
    required this.staff,
    this.initial,
    required this.onChanged,
    this.servKey,
    this.onStaffListChanged,
  });

  final List<StaffMember> staff;
  final ServicioItem? initial;
  final ValueChanged<CustomFormData> onChanged;
  final ServiciosKey? servKey;
  final VoidCallback? onStaffListChanged;

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

  bool _flexibleDuration = false;
  bool _priceFrom = false;
  ServiceSchedulingMode _schedulingMode = ServiceSchedulingMode.general;
  final Set<String> _selectedPros = {};

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
      _durCtrl.text = initial.durationMinutes.toString();
      _priceCtrl.text = initial.priceUyu.toString();
      _flexibleDuration = initial.flexibleDuration;
      _priceFrom = initial.priceFrom;
      _schedulingMode = initial.schedulingMode;
      _selectedPros.addAll(initial.professionalIds);
    }
  }

  List<StaffMember> get _activeStaff =>
      widget.staff.where((m) => m.activo).toList();

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
        durationMinutes: int.tryParse(_durCtrl.text) ?? 60,
        flexibleDuration: _flexibleDuration,
        priceUyu: int.tryParse(_priceCtrl.text) ?? 0,
        priceFrom: _priceFrom,
        schedulingMode: _schedulingMode,
        professionalIds: _selectedPros.toList(),
      ),
    );
  }

  void _setSchedulingMode(ServiceSchedulingMode mode) {
    setState(() {
      _schedulingMode = mode;
      if (mode == ServiceSchedulingMode.general) {
        _selectedPros.clear();
      }
    });
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    final formData = CustomFormData(
      name: _nameCtrl.text,
      description: _descCtrl.text,
      durationMinutes: int.tryParse(_durCtrl.text) ?? 60,
      flexibleDuration: _flexibleDuration,
      priceUyu: int.tryParse(_priceCtrl.text) ?? 0,
      priceFrom: _priceFrom,
      schedulingMode: _schedulingMode,
      professionalIds: _selectedPros.toList(),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Nombre
          EyebrowLabel('NOMBRE DEL SERVICIO'),
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
          EyebrowLabel('DESCRIPCIÓN · opcional'),
          const SizedBox(height: 6),
          _DescriptionField(
            controller: _descCtrl,
            focusNode: _descFocus,
            hasFocus: _descFocus.hasFocus,
            onChanged: (_) => _notify(),
          ),
          const SizedBox(height: 20),

          // 3. Duración + Precio
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

          EyebrowLabel('CÓMO SE AGENDA'),
          const SizedBox(height: 10),
          SchedulingModePicker(
            value: _schedulingMode,
            onChanged: _setSchedulingMode,
          ),
          if (_schedulingMode == ServiceSchedulingMode.byStaff) ...[
            const SizedBox(height: 16),
            StaffAssignmentHint(),
            const SizedBox(height: 12),
            if (_activeStaff.isEmpty)
              EmptyStaffCallout(
                onCreate: widget.servKey == null
                    ? null
                    : () async {
                        await showAddMemberPanel(
                          context,
                          (
                            tenantId: widget.servKey!.tenantId,
                            businessId: widget.servKey!.businessId,
                          ),
                        );
                        if (context.mounted) {
                          widget.onStaffListChanged?.call();
                        }
                      },
              )
            else ...[
              EyebrowLabel('PROFESIONALES QUE LO REALIZAN'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _activeStaff.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final member = entry.value;
                  final color =
                      KTokens.proPalette[idx % KTokens.proPalette.length];
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0x143B2F63)
                            : KTokens.surface,
                        border: Border.all(
                          color:
                              isSelected ? KTokens.accent : KTokens.border,
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
                              color:
                                  isSelected ? KTokens.accent : KTokens.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (widget.servKey != null) ...[
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () async {
                    await showAddMemberPanel(
                      context,
                      (
                        tenantId: widget.servKey!.tenantId,
                        businessId: widget.servKey!.businessId,
                      ),
                    );
                    if (context.mounted) {
                      widget.onStaffListChanged?.call();
                    }
                  },
                  icon: const Icon(Icons.person_add_outlined, size: 18),
                  label: const Text('Agregar otro profesional'),
                  style: TextButton.styleFrom(
                    foregroundColor: KTokens.accent,
                    textStyle: GoogleFonts.inter(fontSize: 13),
                  ),
                ),
              ],
            ],
          ],
          const SizedBox(height: 20),

          // 5. Summary box
          _SummaryBox(formData: formData),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class EyebrowLabel extends StatelessWidget {
  const EyebrowLabel(this.text, {super.key});
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

class SchedulingModePicker extends StatelessWidget {
  const SchedulingModePicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ServiceSchedulingMode value;
  final ValueChanged<ServiceSchedulingMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ModeCard(
            title: 'Agenda general',
            subtitle: 'El cliente reserva sin elegir profesional',
            icon: Icons.storefront_outlined,
            selected: value == ServiceSchedulingMode.general,
            onTap: () => onChanged(ServiceSchedulingMode.general),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ModeCard(
            title: 'Por profesional',
            subtitle: 'El cliente elige quién lo atiende',
            icon: Icons.people_outline_rounded,
            selected: value == ServiceSchedulingMode.byStaff,
            onTap: () => onChanged(ServiceSchedulingMode.byStaff),
          ),
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0x143B2F63) : KTokens.surface,
          border: Border.all(
            color: selected ? KTokens.accent : KTokens.border,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(KTokens.rSm),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: selected ? KTokens.accent : KTokens.inkSoft),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? KTokens.accent : KTokens.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: KTokens.inkMuted,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StaffAssignmentHint extends StatelessWidget {
  const StaffAssignmentHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: KTokens.accentSoft,
        borderRadius: BorderRadius.circular(KTokens.rSm),
        border: Border.all(color: const Color(0x263B2F63)),
      ),
      child: Text(
        'Este servicio se agenda por profesional. Elegí quién puede realizarlo; '
        'también podés asignarlos después desde Equipo.',
        style: GoogleFonts.inter(
          fontSize: 12,
          color: KTokens.accent,
          height: 1.45,
        ),
      ),
    );
  }
}

class EmptyStaffCallout extends StatelessWidget {
  const EmptyStaffCallout({super.key, this.onCreate});

  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: KTokens.border),
        borderRadius: BorderRadius.circular(KTokens.rSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Todavía no hay profesionales en el equipo',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: KTokens.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Creá al menos uno para que el cliente pueda elegir al reservar.',
            style: GoogleFonts.inter(fontSize: 12, color: KTokens.inkMuted),
          ),
          if (onCreate != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.person_add_outlined, size: 18),
              label: const Text('Crear profesional'),
              style: OutlinedButton.styleFrom(
                foregroundColor: KTokens.accent,
                side: const BorderSide(color: KTokens.accent),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  const _SummaryBox({required this.formData});

  final CustomFormData formData;

  @override
  Widget build(BuildContext context) {
    final lines = <String>[];
    lines.add('AL CREAR · APARECE COMO OPCIÓN EN /TU-NEGOCIO');
    if (formData.usesStaff) {
      if (formData.professionalIds.isEmpty) {
        lines.add('AGENDA POR PROFESIONAL · ASIGNÁ QUIÉN LO REALIZA');
      } else {
        final count = formData.professionalIds.length;
        lines.add(
            '$count PROFESIONAL${count > 1 ? 'ES' : ''} PODRÁ${count > 1 ? 'N' : ''} ATENDER RESERVAS');
      }
    } else {
      lines.add('AGENDA GENERAL · SIN ELEGIR PROFESIONAL');
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
