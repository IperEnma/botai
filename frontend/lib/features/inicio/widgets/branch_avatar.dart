import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../agenda/register/konecta_tokens.dart';
import '../models/branch.dart';

class BranchAvatar extends StatelessWidget {
  const BranchAvatar({
    super.key,
    required this.branch,
    required this.turnosCount,
    required this.isSelected,
    required this.onTap,
  });

  final Branch branch;
  final int turnosCount;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: branch.color,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: KTokens.accent.withValues(alpha: 0.35),
                              blurRadius: 0,
                              spreadRadius: 3,
                            )
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      branch.initials,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: branch.status == BranchStatus.activa
                          ? const Color(0xFF34D399)
                          : const Color(0xFFFB923C),
                      border: Border.all(color: KTokens.surface, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              branch.name,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? KTokens.accent : KTokens.ink,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 1),
            Text(
              '$turnosCount TURNOS',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9,
                color: KTokens.inkSoft,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class AllBranchesAvatar extends StatelessWidget {
  const AllBranchesAvatar({
    super.key,
    required this.totalTurnos,
    required this.isSelected,
    required this.onTap,
  });

  final int totalTurnos;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                border: Border.all(
                  color: isSelected ? KTokens.accent : KTokens.ink,
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: KTokens.accent.withValues(alpha: 0.35),
                          blurRadius: 0,
                          spreadRadius: 3,
                        )
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  'Todas',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: KTokens.ink,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Vista global',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? KTokens.accent : KTokens.inkSoft,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 1),
            Text(
              '$totalTurnos TURNOS',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9,
                color: KTokens.inkSoft,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class AddBranchAvatar extends StatelessWidget {
  const AddBranchAvatar({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                border: Border.all(
                  color: const Color(0x33000000),
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.add,
                  size: 22,
                  color: KTokens.inkSoft,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Agregar',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: KTokens.inkSoft,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
