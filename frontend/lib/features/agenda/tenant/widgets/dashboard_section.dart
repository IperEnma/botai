import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/agenda/business.dart';
import '../../../../providers/agenda/tenant/dashboard_provider.dart';

// ── Tokens ────────────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF6366F1);
const _kText    = Color(0xFF0F172A);
const _kTextSub = Color(0xFF64748B);

// ── Public entry point ────────────────────────────────────────────────────────

/// Sección de dashboard completa: filtros + métricas principales + rendimiento.
/// Se monta como un widget normal dentro de un Sliver.
class DashboardSection extends ConsumerStatefulWidget {
  const DashboardSection({
    super.key,
    required this.tenantId,
    required this.businesses,
  });

  final String         tenantId;
  final List<Business> businesses;

  @override
  ConsumerState<DashboardSection> createState() => _DashboardSectionState();
}

class _DashboardSectionState extends ConsumerState<DashboardSection> {
  DateRangePreset _preset      = DateRangePreset.thisWeek;
  String?         _businessId; // null = todas las ubicaciones
  DateTimeRange?  _customRange;

  // Stable date boundaries — only recomputed when the user changes the filter.
  // Storing them in state prevents DateTime.now() from producing a new value on
  // every build(), which would create a new family-provider key each frame and
  // cause an infinite loading loop.
  late DateTime _from;
  late DateTime _to;

  @override
  void initState() {
    super.initState();
    _applyPreset(_preset);
  }

  void _applyPreset(DateRangePreset p) {
    final r = p.range;
    _preset = p;
    _from   = r.from;
    _to     = r.to;
    _customRange = null;
  }

  void _applyCustomRange(DateTimeRange r) {
    _customRange = r;
    _from = r.start;
    _to   = DateTime(r.end.year, r.end.month, r.end.day, 23, 59, 59);
  }

  DashboardFilter get _filter => DashboardFilter(
        tenantId:   widget.tenantId,
        businessId: _businessId,
        from:       _from,
        to:         _to,
      );

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context:   context,
      firstDate: DateTime(2024),
      lastDate:  DateTime.now(),
      initialDateRange: _customRange ??
          DateTimeRange(start: _from, end: DateTime.now()),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _kPrimary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _applyCustomRange(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(dashboardStatsProvider(_filter));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Divider ────────────────────────────────────────────────────────
        Divider(height: 1, color: Colors.grey.shade200),
        const SizedBox(height: 24),

        // ── Filtros ────────────────────────────────────────────────────────
        _FiltersBlock(
          businesses:   widget.businesses,
          selectedBiz:  _businessId,
          preset:       _preset,
          customRange:  _customRange,
          onBizChanged:    (id) => setState(() => _businessId = id),
          onPresetChanged: (p)  => setState(() => _applyPreset(p)),
          onCustomPick:    _pickCustomRange,
        ),

        const SizedBox(height: 24),

        // ── Métricas principales ───────────────────────────────────────────
        statsAsync.when(
          loading: () => const _StatsLoading(),
          error:   (e, _) => _StatsError(onRetry: () => ref.invalidate(dashboardStatsProvider(_filter))),
          data:    (stats) => _MainStatsRow(stats: stats),
        ),

        const SizedBox(height: 16),

        // ── Métricas de rendimiento ────────────────────────────────────────
        statsAsync.maybeWhen(
          data:     (stats) => _PerformanceCard(stats: stats),
          orElse:   () => const SizedBox.shrink(),
        ),

        const SizedBox(height: 32),
      ],
    );
  }
}

// ── Filters block ─────────────────────────────────────────────────────────────

class _FiltersBlock extends StatelessWidget {
  const _FiltersBlock({
    required this.businesses,
    required this.selectedBiz,
    required this.preset,
    required this.customRange,
    required this.onBizChanged,
    required this.onPresetChanged,
    required this.onCustomPick,
  });

  final List<Business>              businesses;
  final String?                     selectedBiz;
  final DateRangePreset             preset;
  final DateTimeRange?              customRange;
  final void Function(String?)      onBizChanged;
  final void Function(DateRangePreset) onPresetChanged;
  final VoidCallback                onCustomPick;

  static String _fmtDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year.toString().substring(2)}';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            'PERÍODO',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _kTextSub,
              letterSpacing: 0.8,
            ),
          ),
        ),

        // Date preset chips + custom
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final p in DateRangePreset.values)
                _FilterChip(
                  label:    p.label,
                  selected: customRange == null && preset == p,
                  onTap:    () => onPresetChanged(p),
                ),
              const SizedBox(width: 4),
              _FilterChip(
                label: customRange != null
                    ? '${_fmtDate(customRange!.start)} – ${_fmtDate(customRange!.end)}'
                    : 'Personalizado',
                selected: customRange != null,
                icon:     Icons.date_range_outlined,
                onTap:    onCustomPick,
              ),
            ],
          ),
        ),

        if (businesses.length > 1) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'UBICACIÓN',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _kTextSub,
                letterSpacing: 0.8,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label:    'Todas',
                  selected: selectedBiz == null,
                  onTap:    () => onBizChanged(null),
                ),
                for (final b in businesses)
                  _FilterChip(
                    label:    b.nombre,
                    selected: selectedBiz == b.id,
                    onTap:    () => onBizChanged(b.id),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ── Generic filter chip ───────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String     label;
  final bool       selected;
  final VoidCallback onTap;
  final IconData?  icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color:        selected ? _kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(50),
          border:       Border.all(
            color: selected ? _kPrimary : Colors.grey.shade300,
          ),
          boxShadow: selected ? [] : [
            BoxShadow(
              color:      Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset:     const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13,
                  color: selected ? Colors.white : _kTextSub),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize:   12,
                fontWeight: FontWeight.w600,
                color:      selected ? Colors.white : _kText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Main stats row (3 cards) ──────────────────────────────────────────────────

class _MainStatsRow extends StatelessWidget {
  const _MainStatsRow({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _StatCard(
              label:   'Pendientes',
              value:   stats.pending + stats.confirmed,
              color:   const Color(0xFFF59E0B),
              bgColor: const Color(0xFFFFFBEB),
              icon:    Icons.schedule_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              label:   'Completadas',
              value:   stats.completed,
              color:   const Color(0xFF10B981),
              bgColor: const Color(0xFFECFDF5),
              icon:    Icons.check_circle_outline_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              label:   'Canceladas',
              value:   stats.cancelled,
              color:   const Color(0xFFEF4444),
              bgColor: const Color(0xFFFFF1F2),
              icon:    Icons.cancel_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
    required this.icon,
  });

  final String  label;
  final int     value;
  final Color   color;
  final Color   bgColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width:  36,
            height: 36,
            decoration: BoxDecoration(
              color:        bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            '$value',
            style: GoogleFonts.poppins(
              fontSize:   28,
              fontWeight: FontWeight.w800,
              color:      _kText,
              height:     1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color:    _kTextSub,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Performance card ──────────────────────────────────────────────────────────

class _PerformanceCard extends StatelessWidget {
  const _PerformanceCard({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width:  32,
                height: 32,
                decoration: BoxDecoration(
                  color:        const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bar_chart_rounded,
                    size: 18, color: _kPrimary),
              ),
              const SizedBox(width: 10),
              Text(
                'Rendimiento',
                style: GoogleFonts.poppins(
                  fontSize:   14,
                  fontWeight: FontWeight.w700,
                  color:      _kText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _PerfTile(
                  label: 'Total agendas',
                  value: '${stats.total}',
                  icon:  Icons.calendar_month_outlined,
                  color: _kPrimary,
                ),
              ),
              Expanded(
                child: _PerfTile(
                  label: 'Tasa completadas',
                  value: '${(stats.completionRate * 100).toStringAsFixed(0)}%',
                  icon:  Icons.trending_up_rounded,
                  color: const Color(0xFF10B981),
                ),
              ),
              Expanded(
                child: _PerfTile(
                  label: 'Tasa cancelaciones',
                  value: '${(stats.cancellationRate * 100).toStringAsFixed(0)}%',
                  icon:  Icons.trending_down_rounded,
                  color: const Color(0xFFEF4444),
                ),
              ),
              Expanded(
                child: _PerfTile(
                  label: 'Prom. diario',
                  value: stats.dailyAvg.toStringAsFixed(1),
                  icon:  Icons.today_outlined,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PerfTile extends StatelessWidget {
  const _PerfTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String   label;
  final String   value;
  final IconData icon;
  final Color    color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize:   18,
            fontWeight: FontWeight.w800,
            color:      _kText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color:    _kTextSub,
            height:   1.3,
          ),
        ),
      ],
    );
  }
}

// ── Loading / error states ────────────────────────────────────────────────────

class _StatsLoading extends StatelessWidget {
  const _StatsLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 120,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color:       _kPrimary,
        ),
      ),
    );
  }
}

class _StatsError extends StatelessWidget {
  const _StatsError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color:        Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded,
              color: Colors.red.shade400, size: 28),
          const SizedBox(height: 8),
          Text(
            'No se pudieron cargar las estadísticas',
            style: GoogleFonts.poppins(
                fontSize: 13, color: Colors.red.shade700),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: Text('Reintentar',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    color:    _kPrimary,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
