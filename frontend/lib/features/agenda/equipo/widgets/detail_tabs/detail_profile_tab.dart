import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../register/konecta_tokens.dart';
import '../../models/member.dart';
import '../../providers/equipo_provider.dart';

class DetailProfileTab extends StatelessWidget {
  const DetailProfileTab({
    super.key,
    required this.member,
    required this.notifier,
  });

  final Member member;
  final EquipoNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final slug = member.name
        .toLowerCase()
        .replaceAll(' ', '-')
        .replaceAll(RegExp(r'[^a-z0-9-]'), '');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // DATOS BÁSICOS
          _SectionLabel('DATOS BÁSICOS'),
          const SizedBox(height: 10),
          _FieldGrid(member: member),
          const SizedBox(height: 20),

          // BIO
          _SectionLabel('BIO PÚBLICA · opcional'),
          const SizedBox(height: 10),
          _BioBox(bio: member.bio),
          const SizedBox(height: 20),

          // COLOR
          _SectionLabel('COLOR IDENTIFICADOR'),
          const SizedBox(height: 10),
          _ColorSection(member: member, notifier: notifier),
          const SizedBox(height: 20),

          // LINK
          _SectionLabel('LINK PERSONAL DE RESERVA'),
          const SizedBox(height: 10),
          _LinkRow(slug: slug),
        ],
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.jetBrainsMono(
        fontSize: 10,
        color: KTokens.inkSoft,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

// ─── Field grid ───────────────────────────────────────────────────────────────

class _FieldGrid extends StatelessWidget {
  const _FieldGrid({required this.member});
  final Member member;

  @override
  Widget build(BuildContext context) {
    final fields = [
      ('NOMBRE', member.name),
      ('WHATSAPP', member.phone ?? '—'),
      ('EMAIL', member.email ?? '—'),
      ('TÍTULO PROFESIONAL', member.title ?? '—'),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 3.2,
      children: fields
          .map((f) => _FieldBox(label: f.$1, value: f.$2))
          .toList(),
    );
  }
}

class _FieldBox extends StatelessWidget {
  const _FieldBox({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: KTokens.surface,
        border: Border.all(color: KTokens.border),
        borderRadius: BorderRadius.circular(KTokens.rSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              color: KTokens.inkSoft,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: KTokens.ink,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Bio box ──────────────────────────────────────────────────────────────────

class _BioBox extends StatelessWidget {
  const _BioBox({required this.bio});
  final String? bio;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: KTokens.surface,
        border: Border.all(color: KTokens.border),
        borderRadius: BorderRadius.circular(KTokens.rSm),
      ),
      child: Text(
        bio ?? 'Sin bio aún.',
        style: GoogleFonts.inter(
          fontSize: 13,
          color: KTokens.inkSoft,
          height: 1.5,
        ),
      ),
    );
  }
}

// ─── Color section ────────────────────────────────────────────────────────────

class _ColorSection extends StatelessWidget {
  const _ColorSection({required this.member, required this.notifier});
  final Member member;
  final EquipoNotifier notifier;

  String _colorName(Color c) {
    final idx = KTokens.proPalette.indexOf(c);
    const names = ['Lila', 'Verde', 'Naranja', 'Azul', 'Rosa', 'Amarillo'];
    if (idx >= 0 && idx < names.length) return names[idx];
    return 'Personalizado';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: KTokens.surface,
        border: Border.all(color: KTokens.border),
        borderRadius: BorderRadius.circular(KTokens.rSm),
      ),
      child: Row(
        children: [
          // Current swatch with ring
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: member.color,
              shape: BoxShape.circle,
              border: Border.all(color: KTokens.accent, width: 2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _colorName(member.color),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: KTokens.ink,
                  ),
                ),
                Text(
                  'SE USA EN EL CALENDARIO',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    color: KTokens.inkSoft,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: KTokens.proPalette.map((c) {
              final isSelected = c == member.color;
              return GestureDetector(
                onTap: () {
                  notifier.updateMember(member.copyWith(color: c));
                },
                child: Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(left: 6),
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: KTokens.accent, width: 2)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Link row ─────────────────────────────────────────────────────────────────

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: KTokens.surface,
        border: Border.all(color: KTokens.border),
        borderRadius: BorderRadius.circular(KTokens.rSm),
      ),
      child: Row(
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'konecta.uy/',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    color: KTokens.inkSoft,
                  ),
                ),
                TextSpan(
                  text: slug,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    color: KTokens.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: 'konecta.uy/$slug'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link copiado')),
              );
            },
            icon: const Icon(Icons.copy, size: 14),
            label: const Text('Copiar'),
            style: TextButton.styleFrom(
              foregroundColor: KTokens.accent,
              textStyle: GoogleFonts.inter(fontSize: 13),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
        ],
      ),
    );
  }
}
