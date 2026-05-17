import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/agenda/agenda_service.dart';
import '../../../../models/agenda/staff_member.dart';
import '../../../../providers/agenda/tenant/business_staff_provider.dart';
import '../../../../providers/agenda/tenant/services_provider.dart';
import '../../register/konecta_tokens.dart';

/// Shows the "Nueva agenda" side panel using [showGeneralDialog].
Future<void> showNewTurnoPanel(
  BuildContext context, {
  required String tenantId,
  required String businessId,
  DateTime? initialDate,
  String? initialProId,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar',
    barrierColor: Colors.black.withValues(alpha: 0.25),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (ctx, anim, secondary) => _NewTurnoPanel(
      tenantId: tenantId,
      businessId: businessId,
      initialDate: initialDate,
      initialProId: initialProId,
    ),
    transitionBuilder: (ctx, anim, secondary, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return Stack(
        children: [
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        ],
      );
    },
  );
}

class _NewTurnoPanel extends ConsumerStatefulWidget {
  const _NewTurnoPanel({
    required this.tenantId,
    required this.businessId,
    this.initialDate,
    this.initialProId,
  });

  final String tenantId;
  final String businessId;
  final DateTime? initialDate;
  final String? initialProId;

  @override
  ConsumerState<_NewTurnoPanel> createState() => _NewTurnoPanelState();
}

class _NewTurnoPanelState extends ConsumerState<_NewTurnoPanel> {
  final _clienteCtrl = TextEditingController();
  final _notasCtrl   = TextEditingController();

  String? _selectedProId;
  final Set<String> _selectedServiceIds = {};
  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;
  bool _sendWhatsApp = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedProId  = widget.initialProId;
    _selectedDate   = widget.initialDate ?? DateTime.now();
    if (widget.initialDate != null) {
      _selectedTime = TimeOfDay(
        hour: widget.initialDate!.hour,
        minute: widget.initialDate!.minute,
      );
    }
  }

  @override
  void dispose() {
    _clienteCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  int get _totalDuration {
    final servicesState = ref.read(
      servicesProvider((tenantId: widget.tenantId, businessId: widget.businessId)),
    );
    return servicesState.items
        .where((s) => _selectedServiceIds.contains(s.id))
        .fold(0, (sum, s) => sum + s.duracionMin);
  }

  DateTime? get _endTime {
    if (_selectedTime == null) return null;
    final start = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    return start.add(Duration(minutes: _totalDuration));
  }

  String get _summaryText {
    final dur = _totalDuration;
    if (dur == 0) return 'Elegí un servicio';
    final end = _endTime;
    if (end == null) return 'DURACIÓN $dur MIN';
    final endStr =
        '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    return 'DURACIÓN $dur MIN · TERMINA $endStr';
  }

  Future<void> _submit() async {
    if (_clienteCtrl.text.trim().isEmpty) {
      _showError('Indicá el nombre del cliente');
      return;
    }
    if (_selectedTime == null) {
      _showError('Elegí una hora');
      return;
    }
    setState(() => _isSubmitting = true);
    // Mock submission — real backend integration goes here
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Turno agendado${_sendWhatsApp ? ' · Confirmación enviada por WhatsApp' : ''}',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        backgroundColor: KTokens.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(fontSize: 13)),
        backgroundColor: KTokens.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final staffState = ref.watch(
      businessStaffProvider((tenantId: widget.tenantId, businessId: widget.businessId)),
    );
    final servicesState = ref.watch(
      servicesProvider((tenantId: widget.tenantId, businessId: widget.businessId)),
    );

    final staff = staffState.members.where((s) => s.activo).toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
    final services = servicesState.items.where((s) => s.activo).toList();

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 460,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 40,
                offset: Offset(-8, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              _PanelHeader(onClose: () => Navigator.of(context).pop()),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // CLIENTE
                      _SectionLabel('CLIENTE'),
                      const SizedBox(height: 8),
                      _ClienteField(controller: _clienteCtrl),
                      const SizedBox(height: 20),

                      // PROFESIONAL
                      _SectionLabel('PROFESIONAL'),
                      const SizedBox(height: 10),
                      if (staffState.isLoading)
                        const SizedBox(
                          height: 36,
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      else
                        _ProChips(
                          staff: staff,
                          selectedId: _selectedProId,
                          onSelect: (id) => setState(() => _selectedProId = id),
                        ),
                      const SizedBox(height: 20),

                      // SERVICIO
                      _SectionLabel('SERVICIO'),
                      const SizedBox(height: 10),
                      if (servicesState.isLoading)
                        const SizedBox(
                          height: 36,
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      else
                        _ServiceChips(
                          services: services,
                          selectedIds: _selectedServiceIds,
                          onToggle: (id) => setState(() {
                            if (_selectedServiceIds.contains(id)) {
                              _selectedServiceIds.remove(id);
                            } else {
                              _selectedServiceIds.add(id);
                            }
                          }),
                        ),
                      const SizedBox(height: 20),

                      // FECHA Y HORA
                      _SectionLabel('FECHA Y HORA'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _DateCard(
                              date: _selectedDate,
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (picked != null) {
                                  setState(() => _selectedDate = picked);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _TimeCard(
                              selectedTime: _selectedTime,
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: _selectedTime ?? TimeOfDay.now(),
                                );
                                if (picked != null) {
                                  setState(() => _selectedTime = picked);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Summary
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: KTokens.accentSoft,
                          borderRadius: BorderRadius.circular(KTokens.rMd),
                        ),
                        child: Text(
                          _summaryText,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            color: KTokens.accent,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // NOTAS
                      _SectionLabel('NOTAS (OPCIONAL)'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _notasCtrl,
                        maxLines: 3,
                        style: GoogleFonts.inter(fontSize: 13, color: KTokens.ink),
                        decoration: InputDecoration(
                          hintText: 'Cualquier dato extra para el turno...',
                          hintStyle: GoogleFonts.inter(fontSize: 13, color: KTokens.inkPlaceholder),
                          filled: true,
                          fillColor: KTokens.bg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(KTokens.rMd),
                            borderSide: BorderSide(color: KTokens.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(KTokens.rMd),
                            borderSide: BorderSide(color: KTokens.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(KTokens.rMd),
                            borderSide: const BorderSide(color: KTokens.accent, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // WhatsApp toggle
                      Row(
                        children: [
                          Switch(
                            value: _sendWhatsApp,
                            onChanged: (v) => setState(() => _sendWhatsApp = v),
                            activeThumbColor: KTokens.accent,
                            activeTrackColor: KTokens.accentSoft,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Enviar confirmación por WhatsApp',
                              style: GoogleFonts.inter(fontSize: 13, color: KTokens.ink),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              // Footer
              _PanelFooter(
                isSubmitting: _isSubmitting,
                onCancel: () => Navigator.of(context).pop(),
                onConfirm: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(28, topPad + 20, 20, 20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: KTokens.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NUEVA AGENDA',
                  style: KTokens.tEyebrow.copyWith(fontSize: 10, letterSpacing: 1.4),
                ),
                const SizedBox(height: 6),
                Text(
                  'Agendá un cliente',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontStyle: FontStyle.italic,
                    color: KTokens.accent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Le mandamos confirmación por WhatsApp al confirmar.',
                  style: GoogleFonts.inter(fontSize: 12, color: KTokens.inkMuted),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, size: 20, color: KTokens.inkMuted),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: KTokens.tEyebrow.copyWith(fontSize: 10, letterSpacing: 1.4),
    );
  }
}

class _ClienteField extends StatelessWidget {
  const _ClienteField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: GoogleFonts.inter(fontSize: 14, color: KTokens.ink),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search, size: 18, color: KTokens.inkSoft),
        hintText: 'Buscar cliente por nombre...',
        hintStyle: GoogleFonts.inter(fontSize: 13, color: KTokens.inkPlaceholder),
        filled: true,
        fillColor: KTokens.bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KTokens.rMd),
          borderSide: BorderSide(color: KTokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KTokens.rMd),
          borderSide: BorderSide(color: KTokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KTokens.rMd),
          borderSide: const BorderSide(color: KTokens.accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
    );
  }
}

class _ProChips extends StatelessWidget {
  const _ProChips({
    required this.staff,
    required this.selectedId,
    required this.onSelect,
  });

  final List<StaffMember> staff;
  final String? selectedId;
  final void Function(String?) onSelect;

  Color _colorFor(int idx) => KTokens.proPalette[idx % KTokens.proPalette.length];

  String _initials(StaffMember s) {
    final parts = s.nombre.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return s.nombre.substring(0, s.nombre.length.clamp(1, 2)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (staff.isEmpty) {
      return Text(
        'Sin profesionales activos',
        style: GoogleFonts.inter(fontSize: 13, color: KTokens.inkMuted),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(staff.length, (i) {
        final s = staff[i];
        final color = _colorFor(i);
        final isSelected = selectedId == s.id;
        return GestureDetector(
          onTap: () => onSelect(isSelected ? null : s.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? KTokens.blockBg(color) : KTokens.bg,
              borderRadius: BorderRadius.circular(KTokens.rPill),
              border: Border.all(
                color: isSelected ? color : KTokens.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.25),
                  ),
                  child: Center(
                    child: Text(
                      _initials(s),
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  s.nombre.split(' ').first,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? color : KTokens.ink,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _ServiceChips extends StatelessWidget {
  const _ServiceChips({
    required this.services,
    required this.selectedIds,
    required this.onToggle,
  });

  final List<AgendaService> services;
  final Set<String> selectedIds;
  final void Function(String) onToggle;

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) {
      return Text(
        'Sin servicios activos',
        style: GoogleFonts.inter(fontSize: 13, color: KTokens.inkMuted),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: services.map((s) {
        final selected = selectedIds.contains(s.id);
        return GestureDetector(
          onTap: () => onToggle(s.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: selected ? KTokens.accentSoft : KTokens.bg,
              borderRadius: BorderRadius.circular(KTokens.rMd),
              border: Border.all(
                color: selected ? KTokens.accent : KTokens.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  s.nombre,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? KTokens.accent : KTokens.ink,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${s.duracionMin}min',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    color: selected ? KTokens.accent : KTokens.inkSoft,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DateCard extends StatelessWidget {
  const _DateCard({required this.date, required this.onTap});
  final DateTime date;
  final VoidCallback onTap;

  static const _months = [
    '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
  ];

  @override
  Widget build(BuildContext context) {
    final label = '${date.day} ${_months[date.month]} ${date.year}';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: KTokens.bg,
          borderRadius: BorderRadius.circular(KTokens.rMd),
          border: Border.all(color: KTokens.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 16, color: KTokens.accent),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FECHA',
                  style: GoogleFonts.jetBrainsMono(fontSize: 9, color: KTokens.inkSoft),
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: KTokens.ink,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeCard extends StatelessWidget {
  const _TimeCard({required this.selectedTime, required this.onTap});
  final TimeOfDay? selectedTime;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = selectedTime == null
        ? 'Elegir hora'
        : '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: KTokens.bg,
          borderRadius: BorderRadius.circular(KTokens.rMd),
          border: Border.all(
            color: selectedTime != null ? KTokens.accent : KTokens.border,
            width: selectedTime != null ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule_outlined, size: 16, color: KTokens.accent),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HORA',
                  style: GoogleFonts.jetBrainsMono(fontSize: 9, color: KTokens.inkSoft),
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selectedTime != null ? KTokens.accent : KTokens.inkMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelFooter extends StatelessWidget {
  const _PanelFooter({
    required this.isSubmitting,
    required this.onCancel,
    required this.onConfirm,
  });

  final bool isSubmitting;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(28, 16, 28, 16 + bottomPad),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: KTokens.border)),
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: isSubmitting ? null : onCancel,
            child: Text(
              'Cancelar',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: KTokens.inkMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: isSubmitting ? null : onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: KTokens.accent,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(KTokens.rMd),
              ),
            ),
            child: isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Confirmar agenda',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward, size: 14),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
