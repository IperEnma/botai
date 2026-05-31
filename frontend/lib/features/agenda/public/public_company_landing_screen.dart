import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/agenda/public_company.dart';
import '../../../providers/agenda/public/public_company_provider.dart';
import '../../../widgets/agenda/agenda_state_views.dart';

const _kPrimary = Color(0xFF6366F1);
const _kText = Color(0xFF0F172A);
const _kTextSub = Color(0xFF64748B);
const _kMaxWidth = 560.0;

/// Entrada estilo Felito Barber: /reservar?company=felitobarber
class PublicCompanyLandingScreen extends ConsumerWidget {
  const PublicCompanyLandingScreen({super.key, required this.companySlug});

  final String companySlug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyAsync = ref.watch(publicCompanyProvider(companySlug));

    return companyAsync.when(
      loading: () => const Scaffold(body: AgendaLoadingView()),
      error: (e, _) => Scaffold(
        body: AgendaErrorView(
          message: 'No encontramos esa marca: $e',
          onRetry: () => ref.refresh(publicCompanyProvider(companySlug)),
        ),
      ),
      data: (company) {
        if (company.branches.length == 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.go('/reservar/${company.branches.first.publicSlug}');
            }
          });
          return const Scaffold(body: AgendaLoadingView());
        }
        return _CompanyLanding(company: company);
      },
    );
  }
}

class _CompanyLanding extends StatelessWidget {
  const _CompanyLanding({required this.company});

  final PublicCompany company;

  Color get _primary {
    final hex = company.colorPrimario;
    if (hex == null) return _kPrimary;
    final val = int.tryParse('FF${hex.replaceAll('#', '')}', radix: 16);
    return val != null ? Color(val) : _kPrimary;
  }

  Color get _bg {
    final hex = company.colorFondo;
    if (hex == null) return const Color(0xFFFAFAFA);
    final val = int.tryParse('FF${hex.replaceAll('#', '')}', radix: 16);
    return val != null ? Color(val) : const Color(0xFFFAFAFA);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _kMaxWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BrandHeader(company: company, primary: _primary),
                  const SizedBox(height: 32),
                  Text(
                    'Elegí tu sucursal',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: _kText,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.separated(
                      itemCount: company.branches.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final branch = company.branches[index];
                        return _BranchCard(
                          branch: branch,
                          primary: _primary,
                          onTap: () => context.go('/reservar/${branch.publicSlug}'),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go('/agenda/me/bookings'),
                    child: Text(
                      'Ver o cancelar mis turnos',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.company, required this.primary});

  final PublicCompany company;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (company.logoUrl != null && company.logoUrl!.startsWith('http'))
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              company.logoUrl!,
              height: 72,
              width: 72,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _InitialsAvatar(name: company.brandName, color: primary),
            ),
          )
        else
          _InitialsAvatar(name: company.brandName, color: primary),
        const SizedBox(height: 16),
        Text(
          company.brandName,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: _kText,
          ),
        ),
        if (company.tagline != null && company.tagline!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            company.tagline!,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 14, color: _kTextSub),
          ),
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Reserva online',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final words = name.trim().split(RegExp(r'\s+'));
    final initials = words.length >= 2
        ? '${words[0][0]}${words[1][0]}'.toUpperCase()
        : name.substring(0, name.length.clamp(1, 2)).toUpperCase();

    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _BranchCard extends StatelessWidget {
  const _BranchCard({
    required this.branch,
    required this.primary,
    required this.onTap,
  });

  final PublicCompanyBranch branch;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      branch.nombre,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _kText,
                      ),
                    ),
                    if (branch.descripcion != null && branch.descripcion!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        branch.descripcion!,
                        style: GoogleFonts.poppins(fontSize: 13, color: _kTextSub),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: primary),
            ],
          ),
        ),
      ),
    );
  }
}
