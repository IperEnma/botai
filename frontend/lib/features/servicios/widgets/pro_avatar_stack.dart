import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/agenda/staff_member.dart';
import '../../agenda/register/konecta_tokens.dart';

class ProAvatarStack extends StatelessWidget {
  const ProAvatarStack({super.key, required this.staff});

  final List<StaffMember> staff;

  @override
  Widget build(BuildContext context) {
    if (staff.isEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_rounded, size: 12, color: KTokens.warn),
          const SizedBox(width: 4),
          Text(
            'Sin profesional',
            style: GoogleFonts.inter(fontSize: 11, color: KTokens.warn),
          ),
        ],
      );
    }

    final visible = staff.take(3).toList();
    final extra = staff.length - visible.length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: visible.length * 18.0 + (extra > 0 ? 24.0 : 4.0),
          height: 22,
          child: Stack(
            children: [
              for (int i = 0; i < visible.length; i++)
                Positioned(
                  left: i * 16.0,
                  child: _Avatar(member: visible[i], index: i),
                ),
              if (extra > 0)
                Positioned(
                  left: visible.length * 16.0,
                  child: _ExtraCount(count: extra),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.member, required this.index});

  final StaffMember member;
  final int index;

  Color get _color =>
      KTokens.proPalette[index % KTokens.proPalette.length];

  String get _initials {
    final parts = member.nombre.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return member.nombre.substring(0, member.nombre.length.clamp(0, 2)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: _color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: GoogleFonts.inter(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1A1233),
        ),
      ),
    );
  }
}

class _ExtraCount extends StatelessWidget {
  const _ExtraCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: KTokens.bg,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        '+$count',
        style: GoogleFonts.jetBrainsMono(fontSize: 8, color: KTokens.inkMuted),
      ),
    );
  }
}
