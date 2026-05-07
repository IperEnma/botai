import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'konecta_tokens.dart';

class RegisterSuccessScreen extends StatelessWidget {
  const RegisterSuccessScreen({super.key, required this.tenantId});

  final String tenantId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KTokens.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated check icon
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: KTokens.accentSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 40,
                      color: KTokens.accent,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  '¡Listo!',
                  style: GoogleFonts.inter(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
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
                    onPressed: () => context.go('/agenda/tenants/$tenantId'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KTokens.ink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(KTokens.rMd),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Ir a mi panel',
                      style: KTokens.tCta.copyWith(color: Colors.white),
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
