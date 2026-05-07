import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Datos mock ────────────────────────────────────────────────────────────────

class _Block {
  const _Block(this.time, this.label, this.bg, this.fg, this.fill);
  final String time;
  final String label;
  final Color bg;
  final Color fg;
  final double fill;
}

const _kBlocks = [
  _Block('09:00', 'Lucía · Corte + barba', Color(0xD9D9C8FF), Color(0xFF1A1233), 0.78),
  _Block('10:30', 'Martín · Color',        Color(0xB39EFF8C), Color(0xFF0D2A05), 0.62),
  _Block('14:15', 'Carla · Manicure',      Color(0xBFFFD2A0), Color(0xFF3A1F00), 0.54),
];

const _kSparkHeights = [40.0, 55.0, 38.0, 70.0, 52.0, 80.0, 95.0];

// ── Colores de la card ────────────────────────────────────────────────────────

const _kGreen        = Color(0xFF9EFF8C);
const _kGreenBg      = Color(0x269EFF8C);
const _kLavender     = Color(0xFFD9C8FF);
const _kSliceBg      = Color(0x0FFFFFFF);
const _kSliceBorder  = Color(0x1AFFFFFF);
const _kWhite55      = Color(0x8CFFFFFF);
const _kWhite50      = Color(0x80FFFFFF);
const _kWhite40      = Color(0x66FFFFFF);

// ═════════════════════════════════════════════════════════════════════════════
// Public widget
// ═════════════════════════════════════════════════════════════════════════════

class AgendaShowcasePanel extends StatelessWidget {
  const AgendaShowcasePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFBFAF7),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2A2247), Color(0xFF3B2F63), Color(0xFF4A3A7A)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x2E281E46),
                    blurRadius: 80,
                    offset: Offset(0, 30),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(),
                  const SizedBox(height: 20),
                  _SliceAgenda(),
                  const SizedBox(height: 12),
                  _SliceNextAppointment(),
                  const SizedBox(height: 12),
                  _SliceStats(),
                  const SizedBox(height: 20),
                  _Footer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUÉ TE ESPERA EN KONECTA',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            letterSpacing: 1.8,
            color: _kWhite50,
          ),
        ),
        const SizedBox(height: 10),
        RichText(
          text: TextSpan(
            style: GoogleFonts.instrumentSerif(fontSize: 24, color: Colors.white, height: 1.2),
            children: [
              const TextSpan(text: 'Una agenda que '),
              TextSpan(
                text: 'conoce',
                style: GoogleFonts.instrumentSerif(
                  fontSize: 24,
                  fontStyle: FontStyle.italic,
                  color: _kLavender,
                ),
              ),
              const TextSpan(text: ' a tus clientes.'),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Slice wrapper ─────────────────────────────────────────────────────────────

class _Slice extends StatelessWidget {
  const _Slice({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kSliceBg,
        border: Border.all(color: _kSliceBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: child,
    );
  }
}

// ── Slice 1 — Mini agenda ─────────────────────────────────────────────────────

class _SliceAgenda extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _Slice(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Martes, 6 mayo',
                  style: GoogleFonts.instrumentSerif(
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                'HOY · 5 TURNOS',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  color: _kWhite50,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._kBlocks.map((b) => _BlockRow(block: b)),
        ],
      ),
    );
  }
}

class _BlockRow extends StatelessWidget {
  const _BlockRow({required this.block});
  final _Block block;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              block.time,
              style: GoogleFonts.jetBrainsMono(fontSize: 11, color: _kWhite50),
            ),
          ),
          Expanded(
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: block.fill,
              child: Container(
                height: 26,
                decoration: BoxDecoration(
                  color: block.bg,
                  borderRadius: BorderRadius.circular(5),
                ),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  block.label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: block.fg,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Slice 2 — Próxima cita ────────────────────────────────────────────────────

class _SliceNextAppointment extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _Slice(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PRÓXIMA CITA',
            style: GoogleFonts.jetBrainsMono(fontSize: 10, color: _kWhite50),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _GradientAvatar(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lucía Méndez',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Mañana · 10:30 · Corte + barba',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        color: _kWhite55,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _Badge(),
            ],
          ),
        ],
      ),
    );
  }
}

class _GradientAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kLavender, _kGreen],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        'LM',
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1A1233),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _kGreenBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'CONFIRMADO',
        style: GoogleFonts.jetBrainsMono(
          fontSize: 9,
          color: _kGreen,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ── Slice 3 — Stats ───────────────────────────────────────────────────────────

class _SliceStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _Slice(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ESTA SEMANA',
            style: GoogleFonts.jetBrainsMono(fontSize: 10, color: _kWhite50),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '12',
                style: GoogleFonts.instrumentSerif(fontSize: 28, color: Colors.white),
              ),
              const SizedBox(width: 6),
              Text(
                'turnos',
                style: GoogleFonts.inter(fontSize: 14, color: _kWhite50),
              ),
              const Spacer(),
              Text(
                '↑ +3 vs sem. anterior',
                style: GoogleFonts.jetBrainsMono(fontSize: 10, color: _kGreen),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _Sparkline(),
        ],
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const maxH = 32.0;
    final maxVal = _kSparkHeights.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: maxH,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (int i = 0; i < _kSparkHeights.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: Container(
                  height: maxH * (_kSparkHeights[i] / maxVal),
                  color: i == _kSparkHeights.length - 1
                      ? _kGreen
                      : const Color(0x99D9C8FF),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: _kGreen,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _kGreen.withValues(alpha: 0.18),
                blurRadius: 0,
                spreadRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'VISTA DEL PROFESIONAL · DEMO',
          style: GoogleFonts.jetBrainsMono(fontSize: 10, color: _kWhite40),
        ),
      ],
    );
  }
}
