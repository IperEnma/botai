import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../agenda/register/konecta_tokens.dart';
import '../../agenda/shared/k_button.dart';
import '../controllers/inicio_controller.dart';

class Greeting extends ConsumerWidget {
  const Greeting({
    super.key,
    required this.ownerName,
    required this.tenantId,
  });

  final String? ownerName;
  final String tenantId;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Buen día';
    if (hour >= 12 && hour < 18) return 'Buena tarde';
    return 'Buena noche';
  }

  String _firstName() {
    if (ownerName == null || ownerName!.trim().isEmpty) return 'ahí';
    return ownerName!.trim().split(' ').first;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inicioControllerProvider(tenantId));
    final snapshot = state.snapshot;
    final isWide = MediaQuery.sizeOf(context).width >= 800;

    final dateStr = DateFormat(
      "EEEE d 'de' MMMM",
      'es',
    ).format(DateTime.now()).toUpperCase();

    final total = snapshot?.turnos.total ?? 0;
    final capacity = snapshot?.turnos.capacity ?? 0;
    final libres = capacity - total;

    final greeting = _greeting();
    final firstName = _firstName();

    final buttons = [
      KButton.secondary(
        label: 'Ver agenda completa',
        icon: Icons.arrow_outward_rounded,
        compact: true,
        onPressed: () => context.go('/agenda/panel?section=agenda'),
      ),
      const SizedBox(width: 10, height: 10),
      KButton.primary(
        label: 'Nueva agenda',
        icon: Icons.add_rounded,
        compact: true,
        onPressed: () => context.go('/agenda/panel?section=agenda'),
      ),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateStr,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  letterSpacing: 1.6,
                  color: KTokens.inkSoft,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$greeting, ',
                      style: KTokens.tDisplay,
                    ),
                    TextSpan(
                      text: '$firstName.',
                      style: KTokens.tDisplay.copyWith(color: KTokens.accent),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$total turnos agendados hoy · $libres espacios libres',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: KTokens.inkMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        if (isWide)
          Row(children: buttons)
        else
          Wrap(
            direction: Axis.horizontal,
            children: buttons,
          ),
      ],
    );
  }
}
