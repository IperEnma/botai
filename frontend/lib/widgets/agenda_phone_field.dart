import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/agenda_phone.dart';
import '../features/agenda/register/konecta_tokens.dart';

/// País para selector de prefijo telefónico.
class AgendaPhoneCountry {
  final String dialCode;
  final String flag;
  final String name;
  final String iso;
  const AgendaPhoneCountry(this.dialCode, this.flag, this.name, this.iso);

  String get dialDigits => dialCode.replaceAll(RegExp(r'\D'), '');
}

const List<AgendaPhoneCountry> kAgendaPhoneCountries = [
  AgendaPhoneCountry('+598', '🇺🇾', 'Uruguay', 'UY'),
  AgendaPhoneCountry('+54', '🇦🇷', 'Argentina', 'AR'),
  AgendaPhoneCountry('+55', '🇧🇷', 'Brasil', 'BR'),
  AgendaPhoneCountry('+56', '🇨🇱', 'Chile', 'CL'),
  AgendaPhoneCountry('+595', '🇵🇾', 'Paraguay', 'PY'),
  AgendaPhoneCountry('+591', '🇧🇴', 'Bolivia', 'BO'),
  AgendaPhoneCountry('+57', '🇨🇴', 'Colombia', 'CO'),
  AgendaPhoneCountry('+52', '🇲🇽', 'México', 'MX'),
  AgendaPhoneCountry('+34', '🇪🇸', 'España', 'ES'),
  AgendaPhoneCountry('+1', '🇺🇸', 'USA', 'US'),
];

AgendaPhoneCountry detectDefaultAgendaPhoneCountry() {
  final iso =
      WidgetsBinding.instance.platformDispatcher.locale.countryCode?.toUpperCase() ?? '';
  return kAgendaPhoneCountries.firstWhere(
    (c) => c.iso == iso,
    orElse: () => kAgendaPhoneCountries.first,
  );
}

/// Parsea un valor canónico (solo dígitos o con `+`) y separa código de país
/// (dial code más largo que matchea como prefijo) del número local. Si no se
/// puede determinar país, usa el detectado por locale.
({AgendaPhoneCountry country, String local}) parseAgendaPhoneValue(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) {
    return (country: detectDefaultAgendaPhoneCountry(), local: '');
  }
  AgendaPhoneCountry? best;
  for (final c in kAgendaPhoneCountries) {
    if (digits.startsWith(c.dialDigits)) {
      if (best == null || c.dialDigits.length > best.dialDigits.length) {
        best = c;
      }
    }
  }
  if (best != null) {
    return (country: best, local: digits.substring(best.dialDigits.length));
  }
  return (country: detectDefaultAgendaPhoneCountry(), local: digits);
}

/// Campo de teléfono con prefijo por país. [controller] recibe el valor canónico (solo dígitos).
class AgendaPhoneField extends StatefulWidget {
  const AgendaPhoneField({
    super.key,
    required this.controller,
    this.required = true,
    this.label = 'Teléfono',
    this.helperText,
    this.useKonectaTokens = true,
    this.labelStyle,
  });

  final TextEditingController controller;
  final bool required;
  final String label;
  final String? helperText;
  final bool useKonectaTokens;

  /// Si se provee, sobreescribe el estilo por defecto del label superior
  /// (útil para encajar con tipografías de secciones puntuales — p. ej. Equipo).
  final TextStyle? labelStyle;

  @override
  State<AgendaPhoneField> createState() => _AgendaPhoneFieldState();
}

class _AgendaPhoneFieldState extends State<AgendaPhoneField> {
  late AgendaPhoneCountry _country;
  final _numCtrl = TextEditingController();
  final _selectorKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final initial = widget.controller.text.trim();
    if (initial.isNotEmpty) {
      final parsed = parseAgendaPhoneValue(initial);
      _country = parsed.country;
      _numCtrl.text = parsed.local;
    } else {
      _country = detectDefaultAgendaPhoneCountry();
    }
    _numCtrl.addListener(_sync);
  }

  @override
  void dispose() {
    _numCtrl.removeListener(_sync);
    _numCtrl.dispose();
    super.dispose();
  }

  void _sync() {
    final local = _numCtrl.text.trim();
    if (local.isEmpty) {
      widget.controller.text = '';
      return;
    }
    widget.controller.text = normalizeAgendaPhoneDigits(
      '${_country.dialCode}$local',
      defaultCountryCode: _country.dialDigits,
    );
  }

  Future<void> _pickCountry() async {
    final box = _selectorKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;
    final origin = box.localToGlobal(Offset.zero, ancestor: overlay);
    final left = origin.dx;
    final top = origin.dy + box.size.height + 4;
    final right = overlay.size.width - origin.dx - box.size.width;

    final picked = await showMenu<AgendaPhoneCountry>(
      context: context,
      initialValue: _country,
      elevation: 4,
      color: widget.useKonectaTokens
          ? KTokens.surface
          : Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          widget.useKonectaTokens ? KTokens.rMd : 12,
        ),
      ),
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 240),
      position: RelativeRect.fromLTRB(left, top, right, 0),
      items: kAgendaPhoneCountries.map((c) {
        final isSel = c.iso == _country.iso;
        return PopupMenuItem<AgendaPhoneCountry>(
          value: c,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Text(c.flag, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  c.name,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: widget.useKonectaTokens ? KTokens.ink : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                c.dialCode,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  color: widget.useKonectaTokens ? KTokens.inkSoft : null,
                ),
              ),
              if (isSel) ...[
                const SizedBox(width: 6),
                const Icon(Icons.check, size: 14, color: KTokens.accent),
              ],
            ],
          ),
        );
      }).toList(),
    );
    if (picked != null && mounted) {
      setState(() => _country = picked);
      _sync();
    }
  }

  @override
  Widget build(BuildContext context) {
    final field = Container(
      decoration: BoxDecoration(
        color: widget.useKonectaTokens ? KTokens.bg : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(widget.useKonectaTokens ? KTokens.rMd : 12),
        border: Border.all(
          color: widget.useKonectaTokens
              ? KTokens.border
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            key: _selectorKey,
            onTap: _pickCountry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: widget.useKonectaTokens
                        ? KTokens.border
                        : Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_country.flag, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text(
                    _country.dialCode,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: widget.useKonectaTokens ? KTokens.ink : null,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 16,
                    color: widget.useKonectaTokens ? KTokens.inkSoft : null,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _numCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.inter(
                fontSize: 14,
                color: widget.useKonectaTokens ? KTokens.ink : null,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: widget.required ? 'Número *' : 'Número (sin repetir código)',
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: widget.useKonectaTokens ? KTokens.inkPlaceholder : null,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
              ),
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.required ? '${widget.label} *' : widget.label,
          style: widget.labelStyle ??
              GoogleFonts.inter(
                fontSize: widget.useKonectaTokens ? 12 : 14,
                fontWeight: FontWeight.w500,
                color: widget.useKonectaTokens ? KTokens.inkMuted : null,
              ),
        ),
        const SizedBox(height: 6),
        field,
        if (widget.helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.helperText!,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: widget.useKonectaTokens ? KTokens.inkSoft : Theme.of(context).hintColor,
            ),
          ),
        ],
      ],
    );
  }
}

