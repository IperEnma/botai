import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../agenda/register/konecta_tokens.dart';
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
      OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          foregroundColor: KTokens.accent,
          side: const BorderSide(color: KTokens.accent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        ),
        child: Text(
          '↑ Ver agenda completa',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      const SizedBox(width: 10, height: 10),
      ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: KTokens.ink,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        ),
        child: Text(
          '+ Nuevo turno',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
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
                      style: GoogleFonts.instrumentSerif(
                        fontSize: 38,
                        fontStyle: FontStyle.italic,
                        color: KTokens.ink,
                        height: 1.1,
                      ),
                    ),
                    TextSpan(
                      text: '$firstName.',
                      style: GoogleFonts.instrumentSerif(
                        fontSize: 38,
                        fontStyle: FontStyle.italic,
                        color: KTokens.accent,
                        height: 1.1,
                      ),
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
