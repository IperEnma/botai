import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../../features/agenda/register/konecta_tokens.dart';
import '../../../../../../../providers/agenda/tenant/horarios_controller_provider.dart';

const _kMonthsFull = [
  '', 'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];

Future<void> showNewExceptionPanel(
  BuildContext context, {
  ExceptionDraft? existing,
  required void Function(ExceptionDraft) onSave,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar',
    barrierColor: Colors.black.withValues(alpha: 0.25),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (ctx, anim, secondary) => _NewExceptionPanel(
      existing: existing,
      onSave: onSave,
    ),
    transitionBuilder: (ctx, anim, secondary, child) {
      final curved =
          CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
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

class _NewExceptionPanel extends StatefulWidget {
  const _NewExceptionPanel({this.existing, required this.onSave});
  final ExceptionDraft? existing;
  final void Function(ExceptionDraft) onSave;

  @override
  State<_NewExceptionPanel> createState() => _NewExceptionPanelState();
}

class _NewExceptionPanelState extends State<_NewExceptionPanel> {
  late ExcType _type;
  late DateTime _dateFrom;
  late DateTime _dateTo;
  TimeOfDay _from1 = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _to1 = const TimeOfDay(hour: 15, minute: 0);
  bool _hasBreak = false;
  TimeOfDay _from2 = const TimeOfDay(hour: 16, minute: 0);
  TimeOfDay _to2 = const TimeOfDay(hour: 19, minute: 0);
  final _reasonCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _type = e.type;
      _dateFrom = e.dateFrom;
      _dateTo = e.dateTo;
      _from1 = e.from1 ?? const TimeOfDay(hour: 9, minute: 0);
      _to1 = e.to1 ?? const TimeOfDay(hour: 15, minute: 0);
      _hasBreak = e.hasBreak;
      _from2 = e.from2 ?? const TimeOfDay(hour: 16, minute: 0);
      _to2 = e.to2 ?? const TimeOfDay(hour: 19, minute: 0);
      _reasonCtrl.text = e.reason ?? '';
    } else {
      _type = ExcType.modifiedHours;
      _dateFrom = DateTime.now();
      _dateTo = DateTime.now();
    }
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  bool get _needsDateRange => _type == ExcType.vacation;
  bool get _needsHours =>
      _type == ExcType.modifiedHours || _type == ExcType.openDay;

  Future<void> _pickDate(bool isFrom) async {
    final initial = isFrom ? _dateFrom : _dateTo;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _dateFrom = picked;
        if (!_needsDateRange) { _dateTo = picked; }
        if (_dateTo.isBefore(_dateFrom)) { _dateTo = _dateFrom; }
      } else {
        _dateTo = picked;
        if (_dateTo.isBefore(_dateFrom)) { _dateFrom = _dateTo; }
      }
    });
  }

  Future<void> _pickTime(bool isFrom, bool isBreak) async {
    TimeOfDay current;
    if (!isBreak) {
      current = isFrom ? _from1 : _to1;
    } else {
      current = isFrom ? _from2 : _to2;
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (!isBreak) {
        if (isFrom) { _from1 = picked; } else { _to1 = picked; }
      } else {
        if (isFrom) { _from2 = picked; } else { _to2 = picked; }
      }
    });
  }

  void _save() {
    final id = widget.existing?.id ??
        DateTime.now().millisecondsSinceEpoch.toString();
    final e = ExceptionDraft(
      id: id,
      type: _type,
      dateFrom: _dateFrom,
      dateTo: _dateTo,
      from1: _needsHours ? _from1 : null,
      to1: _needsHours ? _to1 : null,
      hasBreak: _needsHours && _hasBreak,
      from2: (_needsHours && _hasBreak) ? _from2 : null,
      to2: (_needsHours && _hasBreak) ? _to2 : null,
      reason: _reasonCtrl.text.trim().isEmpty ? null : _reasonCtrl.text.trim(),
    );
    widget.onSave(e);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
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
                      // TIPO
                      _Label('TIPO DE EXCEPCIÓN'),
                      const SizedBox(height: 12),
                      _TypeGrid(
                        selected: _type,
                        onSelect: (t) => setState(() {
                          _type = t;
                          if (!_needsDateRange) _dateTo = _dateFrom;
                        }),
                      ),
                      const SizedBox(height: 20),

                      // FECHA
                      _Label('FECHA'),
                      const SizedBox(height: 10),
                      _needsDateRange
                          ? Row(
                              children: [
                                Expanded(
                                  child: _DateBox(
                                    label: 'DESDE',
                                    date: _dateFrom,
                                    onTap: () => _pickDate(true),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _DateBox(
                                    label: 'HASTA',
                                    date: _dateTo,
                                    onTap: () => _pickDate(false),
                                  ),
                                ),
                              ],
                            )
                          : _DateBox(
                              label: 'FECHA',
                              date: _dateFrom,
                              onTap: () => _pickDate(true),
                            ),
                      const SizedBox(height: 20),

                      // HORARIO (solo si aplica)
                      if (_needsHours) ...[
                        _Label('HORARIO ESE DÍA'),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _TimeBox(
                              time: _from1,
                              onTap: () => _pickTime(true, false),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '→',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: KTokens.inkMuted,
                                ),
                              ),
                            ),
                            _TimeBox(
                              time: _to1,
                              onTap: () => _pickTime(false, false),
                            ),
                          ],
                        ),
                        if (_hasBreak) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _TimeBox(
                                time: _from2,
                                onTap: () => _pickTime(true, true),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  '→',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: KTokens.inkMuted,
                                  ),
                                ),
                              ),
                              _TimeBox(
                                time: _to2,
                                onTap: () => _pickTime(false, true),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => setState(() => _hasBreak = !_hasBreak),
                          child: Text(
                            _hasBreak ? '– Quitar pausa' : '+ Agregar pausa',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: KTokens.accent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // MOTIVO
                      _Label('MOTIVO · opcional'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _reasonCtrl,
                        maxLines: 2,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: KTokens.ink,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ej: Cierre temprano por evento privado...',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 13,
                            color: KTokens.inkPlaceholder,
                          ),
                          filled: true,
                          fillColor: KTokens.bg,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(KTokens.rMd),
                            borderSide: BorderSide(color: KTokens.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(KTokens.rMd),
                            borderSide: BorderSide(color: KTokens.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(KTokens.rMd),
                            borderSide: const BorderSide(
                              color: KTokens.accent,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Warning (hardcoded for demo)
                      _WarningBox(show: _needsHours),
                    ],
                  ),
                ),
              ),
              _PanelFooter(
                onCancel: () => Navigator.of(context).pop(),
                onSave: _save,
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
                  'NUEVA EXCEPCIÓN',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    letterSpacing: 1.4,
                    color: KTokens.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Modificar un día puntual',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontStyle: FontStyle.italic,
                    color: KTokens.accent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Esto sobrescribe el horario regular para esa fecha.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: KTokens.inkMuted,
                  ),
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

class _Label extends StatelessWidget {
  const _Label(this.text);
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

class _TypeGrid extends StatelessWidget {
  const _TypeGrid({required this.selected, required this.onSelect});
  final ExcType selected;
  final void Function(ExcType) onSelect;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.6,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _TypeCard(
          type: ExcType.closed,
          title: 'Cerrar día completo',
          subtitle: 'Feriado, día libre',
          icon: Icons.block_outlined,
          selected: selected == ExcType.closed,
          onTap: onSelect,
        ),
        _TypeCard(
          type: ExcType.modifiedHours,
          title: 'Cambiar horario',
          subtitle: 'Cierre temprano, apertura tardía',
          icon: Icons.schedule_outlined,
          selected: selected == ExcType.modifiedHours,
          onTap: onSelect,
        ),
        _TypeCard(
          type: ExcType.vacation,
          title: 'Vacaciones',
          subtitle: 'Rango de varios días',
          icon: Icons.beach_access_outlined,
          selected: selected == ExcType.vacation,
          onTap: onSelect,
        ),
        _TypeCard(
          type: ExcType.openDay,
          title: 'Abrir día cerrado',
          subtitle: 'Atender un domingo, etc.',
          icon: Icons.door_front_door_outlined,
          selected: selected == ExcType.openDay,
          onTap: onSelect,
        ),
      ],
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final ExcType type;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final void Function(ExcType) onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? KTokens.accentSoft : Colors.white,
          borderRadius: BorderRadius.circular(KTokens.rSm),
          border: Border.all(
            color: selected ? KTokens.accent : KTokens.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? KTokens.accent : KTokens.inkSoft,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: selected ? KTokens.accent : KTokens.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: selected ? KTokens.accent : KTokens.inkMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  const _DateBox({
    required this.label,
    required this.date,
    required this.onTap,
  });
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dayName = const [
      '', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'
    ][date.weekday];
    final dateStr =
        '$dayName ${date.day} de ${_kMonthsFull[date.month]}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: KTokens.bg,
          borderRadius: BorderRadius.circular(KTokens.rMd),
          border: Border.all(color: KTokens.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9,
                color: KTokens.inkSoft,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 13, color: KTokens.accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    dateStr,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: KTokens.ink,
                    ),
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

class _TimeBox extends StatelessWidget {
  const _TimeBox({required this.time, required this.onTap});
  final TimeOfDay time;
  final VoidCallback onTap;

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: KTokens.bg,
          borderRadius: BorderRadius.circular(KTokens.rMd),
          border: Border.all(color: KTokens.accent.withValues(alpha: 0.4)),
        ),
        child: Text(
          _fmt(time),
          style: GoogleFonts.jetBrainsMono(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: KTokens.ink,
          ),
        ),
      ),
    );
  }
}

class _WarningBox extends StatelessWidget {
  const _WarningBox({required this.show});
  final bool show;

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KTokens.excModifiedBg,
        borderRadius: BorderRadius.circular(KTokens.rSm),
        border: Border.all(color: KTokens.excModified.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 16, color: KTokens.excModified),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hay 3 turnos confirmados después de las 15:00',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: KTokens.excModified,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Te avisaremos para reagendarlos con los clientes antes de aplicar el cambio.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: KTokens.excModified,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelFooter extends StatelessWidget {
  const _PanelFooter({required this.onCancel, required this.onSave});
  final VoidCallback onCancel;
  final VoidCallback onSave;

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
            onPressed: onCancel,
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
            onPressed: onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: KTokens.ink,
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(KTokens.rMd),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Guardar excepción',
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
