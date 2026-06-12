import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/agenda/business_hours.dart';
import '../../../models/agenda/staff_member.dart';
import '../../../providers/agenda/agenda_api_provider.dart';
import '../../../providers/agenda/agenda_user_provider.dart';
import '../../../providers/agenda/me_profile_provider.dart';
import '../../../providers/agenda/selected_agenda_business_provider.dart';
import '../../../providers/agenda/tenant/business_hours_provider.dart';
import '../../../providers/agenda/tenant/business_staff_provider.dart';
import '../../../providers/agenda/tenant/businesses_provider.dart';
import '../../../widgets/agenda/agenda_state_views.dart';
import '../register/konecta_tokens.dart';
import '../shared/k_mobile_top_bar.dart';
import 'widgets/agenda_left_nav.dart';

/// Auto-gestión del horario semanal del propio STAFF. Solo accesible para
/// usuarios STAFF puros; OW/TA editan a través del panel Equipo.
class MisHorariosScreen extends ConsumerStatefulWidget {
  const MisHorariosScreen({super.key});

  @override
  ConsumerState<MisHorariosScreen> createState() => _MisHorariosScreenState();
}

class _MisHorariosScreenState extends ConsumerState<MisHorariosScreen> {
  static const _dayKeys = [
    'lunes', 'martes', 'miercoles', 'jueves',
    'viernes', 'sabado', 'domingo',
  ];
  static const _dayLabels = [
    'Lunes', 'Martes', 'Miércoles', 'Jueves',
    'Viernes', 'Sábado', 'Domingo',
  ];

  bool _customEnabled = false;
  Map<String, _DaySchedule>? _draft;
  String? _hydratedStaffId;
  bool _saving = false;

  void _hydrateIfNeeded(StaffMember staff, List<BusinessHours> bizHours) {
    if (_hydratedStaffId == staff.id) return;
    _hydratedStaffId = staff.id;
    final current = staff.customSchedule;
    _customEnabled = current != null && current.isNotEmpty;
    _draft = _readSchedule(current, bizHours);
  }

  Map<String, _DaySchedule> _readSchedule(
      Map<String, dynamic>? src, List<BusinessHours> bizHours) {
    final result = <String, _DaySchedule>{};
    for (var i = 0; i < _dayKeys.length; i++) {
      final key = _dayKeys[i];
      final node = src == null ? null : src[key];
      final biz = bizHours.where((h) => h.diaSemana == i).cast<BusinessHours?>().firstWhere(
            (_) => true,
            orElse: () => null,
          );
      if (node is Map && node['open'] == true) {
        result[key] = _DaySchedule(
          open: true,
          from: node['from']?.toString() ?? biz?.apertura ?? '09:00',
          to: node['to']?.toString() ?? biz?.cierre ?? '18:00',
        );
      } else if (node is Map && node['open'] == false) {
        result[key] = const _DaySchedule(open: false);
      } else {
        // Default desde horario del negocio
        if (biz == null || biz.cerrado) {
          result[key] = const _DaySchedule(open: false);
        } else {
          result[key] = _DaySchedule(
            open: true,
            from: biz.apertura ?? '09:00',
            to: biz.cierre ?? '18:00',
          );
        }
      }
    }
    return result;
  }

  Map<String, dynamic>? _serialize() {
    if (!_customEnabled || _draft == null) return null;
    final out = <String, dynamic>{};
    _draft!.forEach((k, v) {
      if (!v.open) {
        out[k] = {'open': false};
      } else {
        out[k] = {'open': true, 'from': v.from, 'to': v.to};
      }
    });
    return out;
  }

  Future<void> _save(String businessId, String staffId) async {
    setState(() => _saving = true);
    try {
      final api = ref.read(agendaApiServiceProvider);
      await api.updateStaffSchedule(
        businessId: businessId,
        staffId: staffId,
        customSchedule: _serialize(),
      );
      if (!mounted) return;
      // Refrescar la lista de staff para que el calendario tome el cambio.
      ref.invalidate(businessStaffProvider(
          (tenantId: ref.read(meProfileProvider).valueOrNull?.tenantId ?? '',
              businessId: businessId)));
      _showSnack('Horario guardado.');
    } catch (e) {
      if (mounted) _showSnack('No se pudo guardar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(fontSize: 13)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _pickTime(String dayKey, bool isFrom) async {
    final current = _draft![dayKey]!;
    final parts = (isFrom ? current.from : current.to).split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    final v = '${picked.hour.toString().padLeft(2, '0')}:'
        '${picked.minute.toString().padLeft(2, '0')}';
    setState(() {
      _draft![dayKey] = isFrom
          ? current.copyWith(from: v)
          : current.copyWith(to: v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final me = readMeProfileOrEmpty(ref);
    if (me.userId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/login');
      });
      return const Scaffold(body: AgendaLoadingView());
    }
    if (!me.isStaffOnly) {
      // OW/TA gestionan horarios desde Equipo. Acá no tienen nada que hacer.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/agenda/panel?section=agenda');
      });
      return const Scaffold(body: AgendaLoadingView());
    }

    final businessId = ref.watch(selectedAgendaBusinessIdProvider);
    final tenantId = me.tenantId!;
    final nombre = ref.watch(agendaUserProvider).valueOrNull?.nombre;
    final businessesState = ref.watch(businessesProvider(tenantId));
    final businessName = businessesState.items
        .where((b) => b.id == businessId)
        .firstOrNull
        ?.nombre;
    final leftNav = AgendaLeftNav(
      nombre:       nombre,
      businessName: businessName,
      tenantId:     tenantId,
      businessId:   businessId,
    );
    final isWide = MediaQuery.sizeOf(context).width >= 1024.0;

    Widget content;
    if (businessId == null || businessId.isEmpty) {
      content = const AgendaLoadingView();
    } else {
      content = _buildContent(businessId, tenantId, me.userId!);
    }

    if (isWide) {
      return Scaffold(
        backgroundColor: const Color(0xFFFBFAF7),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            leftNav,
            Expanded(child: Scaffold(body: content)),
          ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFFBFAF7),
      drawer: Drawer(width: kAgendaNavWidth, child: leftNav),
      body: Column(
        children: [
          const KMobileTopBar(),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _buildContent(String businessId, String tenantId, String userId) {
    final staffKey = (tenantId: tenantId, businessId: businessId);
    final staffState = ref.watch(businessStaffProvider(staffKey));
    final hoursState = ref
        .watch(businessHoursProvider((tenantId: tenantId, businessId: businessId)));

    if (staffState.isLoading || hoursState.isLoading) {
      return const AgendaLoadingView();
    }
    if (staffState.error != null) {
      return AgendaErrorView(
        message: staffState.error!,
        onRetry: () => ref.read(businessStaffProvider(staffKey).notifier).load(),
      );
    }
    StaffMember? own;
    for (final s in staffState.members) {
      if (s.userId == userId) {
        own = s;
        break;
      }
    }
    if (own == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No tenés un perfil de profesional en esta sucursal. '
            'Pedile al dueño que te agregue al equipo.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: KTokens.inkMuted),
          ),
        ),
      );
    }
    final bizHours = hoursState.hours.isEmpty
        ? List.generate(7,
            (i) => BusinessHours(
                id: '', businessId: businessId, diaSemana: i, cerrado: true))
        : hoursState.hours;
    _hydrateIfNeeded(own, bizHours);

    final ownStaff = own;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mis horarios',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: KTokens.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Definí tu horario semanal recurrente. Los rangos se ajustan '
                'dentro del horario de la sucursal.',
                style: GoogleFonts.inter(fontSize: 13, color: KTokens.inkMuted),
              ),
              const SizedBox(height: 20),
              _customToggleCard(ownStaff.nombre, bizHours),
              if (_customEnabled) ...[
                const SizedBox(height: 16),
                _daysCard(bizHours),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _saving ? null : () => _save(businessId, ownStaff.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KTokens.ink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(KTokens.rSm),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text('Guardar cambios',
                            style: GoogleFonts.inter(
                                fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _customToggleCard(String memberName, List<BusinessHours> bizHours) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: KTokens.border),
        borderRadius: BorderRadius.circular(KTokens.rSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Horario personalizado',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: KTokens.ink,
                  ),
                ),
              ),
              Switch(
                value: _customEnabled,
                onChanged: (v) {
                  setState(() {
                    _customEnabled = v;
                    if (v && (_draft == null || _draft!.isEmpty)) {
                      _draft = _readSchedule(null, bizHours);
                    }
                  });
                },
                activeThumbColor: KTokens.accent,
                activeTrackColor: KTokens.accentSoft,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'CUANDO ESTÁ OFF, HEREDÁS EL HORARIO DEL NEGOCIO',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              color: KTokens.inkSoft,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _daysCard(List<BusinessHours> bizHours) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: KTokens.border),
        borderRadius: BorderRadius.circular(KTokens.rSm),
      ),
      child: Column(
        children: [
          for (var i = 0; i < _dayKeys.length; i++) ...[
            _dayRow(i, bizHours),
            if (i < _dayKeys.length - 1)
              Divider(height: 1, color: KTokens.border),
          ],
        ],
      ),
    );
  }

  Widget _dayRow(int index, List<BusinessHours> bizHours) {
    final key = _dayKeys[index];
    final label = _dayLabels[index];
    final day = _draft![key]!;
    final biz =
        bizHours.where((h) => h.diaSemana == index).cast<BusinessHours?>().firstWhere(
              (_) => true,
              orElse: () => null,
            );
    final bizClosed = biz == null || biz.cerrado;
    final canOpen = !bizClosed;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: canOpen ? KTokens.ink : KTokens.inkSoft,
              ),
            ),
          ),
          Switch(
            value: day.open && canOpen,
            onChanged: !canOpen
                ? null
                : (v) => setState(() {
                      _draft![key] = day.copyWith(open: v);
                    }),
            activeThumbColor: KTokens.accent,
            activeTrackColor: KTokens.accentSoft,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: !canOpen
                ? Text(
                    'Cerrado en el negocio',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: KTokens.inkSoft),
                  )
                : !day.open
                    ? Text(
                        'Día libre',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: KTokens.inkSoft),
                      )
                    : Row(
                        children: [
                          _timeChip(day.from, () => _pickTime(key, true)),
                          const SizedBox(width: 6),
                          Text('—',
                              style:
                                  GoogleFonts.inter(color: KTokens.inkSoft)),
                          const SizedBox(width: 6),
                          _timeChip(day.to, () => _pickTime(key, false)),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _timeChip(String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: KTokens.bg,
          border: Border.all(color: KTokens.border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          value,
          style: GoogleFonts.jetBrainsMono(
              fontSize: 12, color: KTokens.ink, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class _DaySchedule {
  final bool open;
  final String from;
  final String to;

  const _DaySchedule({required this.open, this.from = '09:00', this.to = '18:00'});

  _DaySchedule copyWith({bool? open, String? from, String? to}) =>
      _DaySchedule(
        open: open ?? this.open,
        from: from ?? this.from,
        to: to ?? this.to,
      );
}
