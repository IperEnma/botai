import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../features/agenda/register/konecta_tokens.dart';
import '../widgets/channels_roadmap.dart';
import '../widgets/mock_chat.dart';
import '../widgets/plan_bar.dart';

class BotsEmptyView extends StatelessWidget {
  const BotsEmptyView({super.key, required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PageHeader(),
          const SizedBox(height: 22),
          const PlanBar(),
          const SizedBox(height: 22),
          _EmptyHero(onCreate: onCreate),
          const SizedBox(height: 22),
          const ChannelsRoadmap(),
        ],
      ),
    );
  }
}

// ─── Page header ──────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AUTOMATIZACIÓN',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            letterSpacing: 1.4,
            color: KTokens.accent,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Mis bots',
          style: GoogleFonts.playfairDisplay(
            fontSize: 36,
            fontStyle: FontStyle.italic,
            color: KTokens.ink,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Asistentes que responden a tus clientes en WhatsApp. Cada uno tiene un propósito distinto — saludar, agendar, dar soporte.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: KTokens.inkMuted,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

// ─── Empty hero ───────────────────────────────────────────────────────────────

class _EmptyHero extends StatelessWidget {
  const _EmptyHero({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KTokens.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: KTokens.border),
      ),
      padding: const EdgeInsets.fromLTRB(40, 44, 40, 44),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 640;
          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 6, child: _HeroLeft(onCreate: onCreate)),
                const SizedBox(width: 40),
                const Expanded(flex: 5, child: MockChat()),
              ],
            );
          }
          return Column(
            children: [
              _HeroLeft(onCreate: onCreate),
              const SizedBox(height: 32),
              const MockChat(),
            ],
          );
        },
      ),
    );
  }
}

class _HeroLeft extends StatelessWidget {
  const _HeroLeft({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'EMPEZÁ ACÁ',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            letterSpacing: 1.4,
            color: KTokens.accent,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        RichText(
          text: TextSpan(
            style: GoogleFonts.playfairDisplay(
              fontSize: 38,
              fontStyle: FontStyle.italic,
              color: KTokens.ink,
              height: 1.2,
            ),
            children: const [
              TextSpan(text: 'Tu primer bot,\nen '),
              TextSpan(
                text: '5 minutos.',
                style: TextStyle(color: KTokens.accent),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Text(
            'Conectá WhatsApp, elegí un propósito y tu bot empieza a responder. No necesita programación — vos contás qué hace tu negocio y aprende.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: KTokens.inkMuted,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: onCreate,
          style: ElevatedButton.styleFrom(
            backgroundColor: KTokens.ink,
            foregroundColor: Colors.white,
            elevation: 0,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(KTokens.rSm),
            ),
            textStyle:
                GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          child: const Text('+ Crear mi primer bot'),
        ),
      ],
    );
  }
}
