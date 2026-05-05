import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/config.dart';
import '../../providers/agenda/agenda_user_provider.dart';

const _kPrimary = Color(0xFF6366F1);
const _kAccent  = Color(0xFF8B5CF6);
const _kSurface = Color(0xFFF8FAFC);
const _kDark    = Color(0xFF0F172A);
const _kMuted   = Color(0xFF64748B);

/// Panel de onboarding en `/agenda/onboarding`.
class AgendaLandingScreen extends ConsumerWidget {
  const AgendaLandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(agendaUserProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        backgroundColor: _kSurface,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, s) => _PanelScaffold(
        child: _NoBusiness(context: context),
      ),
      data: (user) => _PanelScaffold(
        child: user.hasBusiness
            ? _FullPanel(context: context, tenantId: user.tenantId!)
            : _NoBusiness(context: context),
      ),
    );
  }
}

// ── Shell ─────────────────────────────────────────────────────────────────────

class _PanelScaffold extends StatelessWidget {
  const _PanelScaffold({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kSurface,
      body: Column(
        children: [
          _PanelHero(onBack: () => context.go('/agenda')),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

// ── No business — onboarding inline ──────────────────────────────────────────

class _NoBusiness extends StatelessWidget {
  const _NoBusiness({required this.context});
  final BuildContext context;

  @override
  Widget build(BuildContext outerContext) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Text(
          'Bienvenido 👋',
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: _kDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '¿Qué querés hacer ahora?',
          style: GoogleFonts.poppins(fontSize: 14, color: _kMuted, height: 1.5),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _kPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => outerContext.go('/agenda'),
            child: Text(
              'Explorar servicios',
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _kPrimary, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => outerContext.go('/agenda/register'),
            child: Text(
              'Crear mi negocio',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Full panel — user has a business ─────────────────────────────────────────

class _FullPanel extends StatelessWidget {
  const _FullPanel({required this.context, required this.tenantId});
  final BuildContext context;
  final String tenantId;

  @override
  Widget build(BuildContext outerContext) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '¿Qué querés hacer?',
          style: GoogleFonts.poppins(
              fontSize: 22, fontWeight: FontWeight.w700, color: _kDark),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.search_rounded,
                iconBg: const Color(0xFFEEF2FF),
                iconColor: _kPrimary,
                title: 'Buscar negocios',
                subtitle: 'Explorá la agenda pública',
                onTap: () => outerContext.go('/agenda'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _ActionCard(
                icon: Icons.business_center_rounded,
                iconBg: const Color(0xFFEEF2FF),
                iconColor: _kPrimary,
                title: 'Registrar mi negocio',
                subtitle: 'Administrá tu local, servicios y reservas',
                onTap: () => outerContext.go('/agenda/tenants/$tenantId'),
              ),
            ),
          ],
        ),
        if (AppConfig.agendaPlatformAdmin) ...[
          const SizedBox(height: 16),
          _PanelTile(
            icon: Icons.admin_panel_settings_rounded,
            iconBg: const Color(0xFFFFF7ED),
            iconColor: const Color(0xFFF97316),
            title: 'Plataforma',
            subtitle: 'Catálogo global de categorías',
            onTap: () => outerContext.go('/agenda/platform/categories'),
          ),
        ],
      ],
    );
  }
}

// ── Hero ──────────────────────────────────────────────────────────────────────

class _PanelHero extends StatelessWidget {
  const _PanelHero({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kPrimary, _kAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 14,
        20,
        28,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.calendar_month_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mi Panel',
                  style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
                Text(
                  'Reservas, billetera y fidelización',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action card (2-column grid) ───────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kDark,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                    fontSize: 11, color: _kMuted, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Panel tile ────────────────────────────────────────────────────────────────

class _PanelTile extends StatelessWidget {
  const _PanelTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _kDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(fontSize: 12, color: _kMuted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
