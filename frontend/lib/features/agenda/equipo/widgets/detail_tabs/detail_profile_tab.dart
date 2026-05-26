import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../register/konecta_tokens.dart';
import '../../models/member.dart';
import '../../providers/equipo_provider.dart';

class DetailProfileTab extends StatefulWidget {
  const DetailProfileTab({
    super.key,
    required this.member,
    required this.notifier,
  });

  final Member member;
  final EquipoNotifier notifier;

  @override
  State<DetailProfileTab> createState() => _DetailProfileTabState();
}

class _DetailProfileTabState extends State<DetailProfileTab> {
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _titleCtrl;
  late TextEditingController _bioCtrl;

  late FocusNode _phoneFocus;
  late FocusNode _emailFocus;
  late FocusNode _titleFocus;
  late FocusNode _bioFocus;

  @override
  void initState() {
    super.initState();
    _initAll(widget.member);
  }

  void _initAll(Member m) {
    _phoneCtrl = TextEditingController(text: m.phone ?? '');
    _emailCtrl = TextEditingController(text: m.email ?? '');
    _titleCtrl = TextEditingController(text: m.title ?? '');
    _bioCtrl = TextEditingController(text: m.bio ?? '');

    _phoneFocus = FocusNode();
    _emailFocus = FocusNode();
    _titleFocus = FocusNode();
    _bioFocus = FocusNode();

    for (final node in [_phoneFocus, _emailFocus, _titleFocus, _bioFocus]) {
      node.addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void didUpdateWidget(covariant DetailProfileTab old) {
    super.didUpdateWidget(old);
    if (old.member.id != widget.member.id) {
      _disposeAll();
      _initAll(widget.member);
    }
  }

  void _disposeAll() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _titleCtrl.dispose();
    _bioCtrl.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _titleFocus.dispose();
    _bioFocus.dispose();
  }

  @override
  void dispose() {
    _disposeAll();
    super.dispose();
  }

  void _propagate() {
    widget.notifier.updateMember(widget.member.copyWith(
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
      bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // DATOS BÁSICOS
          _SectionLabel('DATOS BÁSICOS'),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 3.2,
            children: [
              _FieldBox(
                label: 'NOMBRE',
                value: widget.member.name,
              ),
              _EditableFieldBox(
                label: 'WHATSAPP',
                ctrl: _phoneCtrl,
                focusNode: _phoneFocus,
                keyboard: TextInputType.phone,
                onChanged: _propagate,
              ),
              _EditableFieldBox(
                label: 'EMAIL',
                ctrl: _emailCtrl,
                focusNode: _emailFocus,
                keyboard: TextInputType.emailAddress,
                onChanged: _propagate,
              ),
              _EditableFieldBox(
                label: 'TÍTULO PROFESIONAL',
                ctrl: _titleCtrl,
                focusNode: _titleFocus,
                onChanged: _propagate,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // BIO
          _SectionLabel('BIO PÚBLICA · opcional'),
          const SizedBox(height: 10),
          _EditableBioBox(
            ctrl: _bioCtrl,
            focusNode: _bioFocus,
            onChanged: _propagate,
          ),
          const SizedBox(height: 20),

          // COLOR
          _SectionLabel('COLOR IDENTIFICADOR'),
          const SizedBox(height: 10),
          _ColorSection(member: widget.member, notifier: widget.notifier),
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

// ─── Read-only field box (NOMBRE) ─────────────────────────────────────────────

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

// ─── Editable field box ───────────────────────────────────────────────────────

class _EditableFieldBox extends StatelessWidget {
  const _EditableFieldBox({
    required this.label,
    required this.ctrl,
    required this.focusNode,
    required this.onChanged,
    this.keyboard,
  });

  final String label;
  final TextEditingController ctrl;
  final FocusNode focusNode;
  final VoidCallback onChanged;
  final TextInputType? keyboard;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => focusNode.requestFocus(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: KTokens.surface,
          border: Border.all(
            color: focusNode.hasFocus ? KTokens.ink : KTokens.border,
            width: 1.5,
          ),
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
            TextField(
              controller: ctrl,
              focusNode: focusNode,
              onChanged: (_) => onChanged(),
              keyboardType: keyboard,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: KTokens.ink,
              ),
              decoration: const InputDecoration(
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Editable bio box ─────────────────────────────────────────────────────────

class _EditableBioBox extends StatelessWidget {
  const _EditableBioBox({
    required this.ctrl,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController ctrl;
  final FocusNode focusNode;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => focusNode.requestFocus(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: KTokens.surface,
          border: Border.all(
            color: focusNode.hasFocus ? KTokens.ink : KTokens.border,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(KTokens.rSm),
        ),
        child: TextField(
          controller: ctrl,
          focusNode: focusNode,
          onChanged: (_) => onChanged(),
          maxLines: 3,
          minLines: 2,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: KTokens.inkSoft,
            height: 1.5,
          ),
          decoration: InputDecoration(
            filled: false,
            isDense: true,
            contentPadding: EdgeInsets.zero,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            hintText: 'Sin bio aún.',
            hintStyle: GoogleFonts.inter(
              fontSize: 13,
              color: KTokens.inkMuted,
            ),
          ),
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
                onTap: () => notifier.updateMember(member.copyWith(color: c)),
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

