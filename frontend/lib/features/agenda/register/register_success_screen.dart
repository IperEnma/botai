import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../navigation/agenda_tenant_nav.dart';
import 'konecta_tokens.dart';

class RegisterSuccessScreen extends ConsumerWidget {
  const RegisterSuccessScreen({super.key, required this.businessId});

  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: KTokens.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: KTokens.accentSoft,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: 40,
                          color: KTokens.accent,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                Text(
                  '¡Listo!',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32,
                    fontStyle: FontStyle.italic,
                    color: KTokens.ink,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tu negocio fue registrado',
                  style: KTokens.tHint,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () =>
                        navigateAgendaTenantBusiness(context, ref, businessId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KTokens.ink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(KTokens.rPill),
                      ),
                    ),
                    child: Text(
                      'Ir al panel',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
