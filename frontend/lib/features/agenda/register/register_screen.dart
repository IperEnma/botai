import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../providers/agenda/agenda_api_provider.dart';
import '../../../services/agenda_api_exception.dart';
import 'konecta_tokens.dart';

// ── Country data ──────────────────────────────────────────────────────────────

class Country {
  const Country({
    required this.name,
    required this.dialCode,
    required this.isoCode,
    required this.minLength,
    required this.maxLength,
  });
  final String name;
  final String dialCode;
  final String isoCode;
  final int minLength;
  final int maxLength;
}

const _countries = [
  Country(name: 'Uruguay',   dialCode: '+598', isoCode: 'UY', minLength: 8,  maxLength: 9),
  Country(name: 'Argentina', dialCode: '+54',  isoCode: 'AR', minLength: 10, maxLength: 10),
  Country(name: 'Colombia',  dialCode: '+57',  isoCode: 'CO', minLength: 10, maxLength: 10),
  Country(name: 'Venezuela', dialCode: '+58',  isoCode: 'VE', minLength: 10, maxLength: 10),
];

// ── Screen ────────────────────────────────────────────────────────────────────

enum _Step { phone, code }

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _phoneCtrl = TextEditingController();
  final _codeCtrl  = TextEditingController();
  final _nameCtrl  = TextEditingController();

  _Step   _step            = _Step.phone;
  Country _country         = _countries.first;
  String  _phone           = '';
  bool    _isPhoneValid    = false;
  bool    _loading         = false;
  String? _error;

  bool get _isFormValid =>
      _nameCtrl.text.trim().length >= 2 && _isPhoneValid;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  // ── Teléfono ───────────────────────────────────────────────────────────────

  void _onPhoneChanged(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    final valid  = digits.length >= _country.minLength &&
                   digits.length <= _country.maxLength;
    setState(() {
      _phone        = '${_country.dialCode}$digits';
      _isPhoneValid = valid;
    });
  }

  // ── Enviar código ──────────────────────────────────────────────────────────

  void _sendCode() {
    if (!_isFormValid) return;
    setState(() { _step = _Step.code; _error = null; });
    // TODO: integrar envío real por WhatsApp
  }

  // ── Verificar código ───────────────────────────────────────────────────────

  Future<void> _verifyCode() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      // TODO: integrar verificación real con la API
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (mounted) context.go('/agenda/intent');
    } catch (e) {
      setState(() => _error = 'Código incorrecto. Intentá de nuevo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _backToPhone() {
    _codeCtrl.clear();
    setState(() { _step = _Step.phone; _error = null; });
  }

  // ── Login con código de acceso ─────────────────────────────────────────────

  Future<void> _loginWithCode(String accessCode) async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final api      = ref.read(agendaApiServiceProvider);
      final tenantId = await api.getTenantByCode(accessCode);
      if (!mounted) return;
      context.go('/agenda/tenants/$tenantId');
    } on AgendaApiException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(e.status == 404
            ? 'Código no encontrado. Verificá que sea correcto.'
            : e.message),
        backgroundColor: KTokens.errorColor,
      ));
    }
  }

  void _showLoginDialog() {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: KTokens.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ingresar con código',
                  style: KTokens.tQuestion.copyWith(fontSize: 18)),
              const SizedBox(height: 8),
              Text(
                'Ingresá el código de 8 caracteres que recibiste al registrarte.',
                style: KTokens.tHint,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: ctrl,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                maxLength: 8,
                style: KTokens.tInput.copyWith(letterSpacing: 4, fontSize: 18),
                cursorColor: KTokens.accent,
                decoration: InputDecoration(
                  hintText: 'K7MN2PQX',
                  hintStyle: KTokens.tInput.copyWith(
                      color: KTokens.inkPlaceholder, letterSpacing: 4, fontSize: 18),
                  border: const UnderlineInputBorder(
                      borderSide: BorderSide(color: KTokens.accent)),
                  focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: KTokens.accent, width: 2)),
                  enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: KTokens.borderStrong)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text('Cancelar',
                        style: KTokens.tCta.copyWith(color: KTokens.inkMuted)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KTokens.ink,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(KTokens.rMd)),
                    ),
                    onPressed: () {
                      final code = ctrl.text.trim().toUpperCase();
                      if (code.length < 8) return;
                      Navigator.of(ctx).pop();
                      _loginWithCode(code);
                    },
                    child: Text('Ingresar',
                        style: KTokens.tCta.copyWith(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KTokens.bg,
      body: Stack(
        children: [
          const _BackgroundCards(),
          SafeArea(
            child: Column(
              children: [
                _NavBar(
                  onBack: () =>
                      context.canPop() ? context.pop() : context.go('/agenda'),
                  onLogin: _showLoginDialog,
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 20),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          transitionBuilder: (child, anim) =>
                              FadeTransition(opacity: anim, child: child),
                          child: _step == _Step.phone
                              ? _buildPhone()
                              : _buildCode(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── PASO TELÉFONO ──────────────────────────────────────────────────────────

  Widget _buildPhone() {
    return Column(
      key: const ValueKey('phone'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'BIENVENIDO',
          textAlign: TextAlign.center,
          style: KTokens.tEyebrow.copyWith(
              fontSize: 11, letterSpacing: 2.5, color: KTokens.inkSoft),
        ),
        const SizedBox(height: 10),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Empezá en ',
                style: GoogleFonts.inter(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: KTokens.ink,
                  letterSpacing: -1,
                  height: 1.1,
                ),
              ),
              TextSpan(
                text: '30 segundos.',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 38,
                  fontStyle: FontStyle.italic,
                  color: KTokens.accent,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Te enviamos un código por WhatsApp y listo.\nEl resto lo configurás después.',
          textAlign: TextAlign.center,
          style: KTokens.tHint.copyWith(height: 1.6),
        ),
        const SizedBox(height: 44),
        // ── Nombre ────────────────────────────────────────────────────────
        _NameInput(
          controller: _nameCtrl,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 32),
        // ── Teléfono ──────────────────────────────────────────────────────
        _PhoneInput(
          country: _country,
          controller: _phoneCtrl,
          onCountrySelected: (c) {
            setState(() => _country = c);
            _onPhoneChanged(_phoneCtrl.text);
          },
          onChanged: _onPhoneChanged,
          onSubmitted: _isFormValid ? (_) => _sendCode() : null,
        ),
        const SizedBox(height: 40),
        _SendButton(
          label: 'Enviar código',
          enabled: _isFormValid,
          loading: false,
          onPressed: _sendCode,
        ),
        const SizedBox(height: 28),
        const _WaDivider(label: 'O CON GOOGLE'),
        const SizedBox(height: 28),
        _GoogleButton(),
        const SizedBox(height: 28),
        Center(
          child: GestureDetector(
            onTap: _showLoginDialog,
            child: RichText(
              text: TextSpan(
                style: KTokens.tHint,
                children: [
                  const TextSpan(text: '¿Ya tenés cuenta? '),
                  TextSpan(
                    text: 'Iniciar sesión',
                    style: KTokens.tHint.copyWith(
                      color: KTokens.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Al continuar aceptás nuestros Términos y la Política de privacidad.',
          textAlign: TextAlign.center,
          style: KTokens.tHint.copyWith(fontSize: 11, color: KTokens.inkSoft),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── PASO CÓDIGO ────────────────────────────────────────────────────────────

  Widget _buildCode() {
    return Column(
      key: const ValueKey('code'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'VERIFICACIÓN',
          textAlign: TextAlign.center,
          style: KTokens.tEyebrow.copyWith(
              fontSize: 11, letterSpacing: 2.5, color: KTokens.inkSoft),
        ),
        const SizedBox(height: 16),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Revisá tu ',
                style: GoogleFonts.inter(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: KTokens.ink,
                  letterSpacing: -1,
                  height: 1.1,
                ),
              ),
              TextSpan(
                text: 'WhatsApp.',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 38,
                  fontStyle: FontStyle.italic,
                  color: KTokens.accent,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: KTokens.tHint.copyWith(height: 1.5),
            children: [
              const TextSpan(text: 'Te enviamos el código a '),
              TextSpan(
                text: _phone,
                style: KTokens.tHint.copyWith(
                    fontWeight: FontWeight.w600, color: KTokens.ink),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // Code input
        _CodeInput(controller: _codeCtrl),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: KTokens.tError, textAlign: TextAlign.center),
        ],
        const SizedBox(height: 28),
        _SendButton(
          label: 'Verificar código',
          enabled: true,
          loading: _loading,
          onPressed: _loading ? null : _verifyCode,
        ),
        const SizedBox(height: 16),
        Center(
          child: GestureDetector(
            onTap: _backToPhone,
            child: Text(
              'Cambiar número',
              style: KTokens.tHint.copyWith(
                color: KTokens.inkMuted,
                decoration: TextDecoration.underline,
                decorationColor: KTokens.inkMuted,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── Nav bar ───────────────────────────────────────────────────────────────────

class _NavBar extends StatelessWidget {
  const _NavBar({required this.onBack, required this.onLogin});

  final VoidCallback onBack;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 24, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: KTokens.borderStrong),
              ),
              child: const Icon(Icons.arrow_back, size: 15, color: KTokens.ink),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'konecta',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: KTokens.ink,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onLogin,
            child: Text(
              'CREAR CUENTA',
              style: KTokens.tEyebrow.copyWith(
                  letterSpacing: 1.4, color: KTokens.ink),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Google button ─────────────────────────────────────────────────────────────

class _GoogleButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: KTokens.surface,
          side: const BorderSide(color: KTokens.borderStrong),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(KTokens.rMd)),
        ),
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Sign-In próximamente')),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _GoogleG(),
            const SizedBox(width: 10),
            Text(
              'Continuar con Google',
              style: KTokens.tCta.copyWith(
                  color: KTokens.ink,
                  fontWeight: FontWeight.w500,
                  fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleG extends StatelessWidget {
  const _GoogleG();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = math.min(cx, cy);
    final stroke = r * 0.28;
    final rect   = Rect.fromCircle(center: Offset(cx, cy), radius: r - stroke / 2);

    void arc(Color color, double start, double sweep) {
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.butt,
      );
    }

    const pi = math.pi;
    arc(const Color(0xFF4285F4), -pi / 2,            pi * 0.5);
    arc(const Color(0xFFEA4335), pi,                 pi * 0.5);
    arc(const Color(0xFFFBBC05), pi / 2,             pi * 0.5);
    arc(const Color(0xFF34A853), 0,                  pi * 0.5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── "O CON WHATSAPP" divider ──────────────────────────────────────────────────

class _WaDivider extends StatelessWidget {
  const _WaDivider({this.label = 'O CON WHATSAPP'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
            child: Divider(color: KTokens.borderStrong, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: KTokens.tEyebrow.copyWith(
                letterSpacing: 1.5, color: KTokens.inkSoft),
          ),
        ),
        const Expanded(
            child: Divider(color: KTokens.borderStrong, thickness: 1)),
      ],
    );
  }
}

// ── Name input ────────────────────────────────────────────────────────────────

class _NameInput extends StatelessWidget {
  const _NameInput({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const underline = UnderlineInputBorder(
        borderSide: BorderSide(color: KTokens.accent, width: 1.5));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tu nombre', style: KTokens.tHint),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
          onChanged: onChanged,
          cursorColor: KTokens.accent,
          cursorWidth: 2,
          style: KTokens.tInput.copyWith(fontSize: 18),
          decoration: InputDecoration(
            hintText: 'Ej: Ana López',
            hintStyle: KTokens.tInput
                .copyWith(fontSize: 18, color: KTokens.inkPlaceholder),
            border: underline,
            enabledBorder: underline,
            focusedBorder: underline,
            contentPadding: const EdgeInsets.only(bottom: 8),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('nombre completo', style: KTokens.tMonoHint),
            Text('↵ siguiente',     style: KTokens.tMonoHint),
          ],
        ),
      ],
    );
  }
}

// ── Phone input ───────────────────────────────────────────────────────────────

class _PhoneInput extends StatefulWidget {
  const _PhoneInput({
    required this.country,
    required this.controller,
    required this.onCountrySelected,
    required this.onChanged,
    this.onSubmitted,
  });

  final Country country;
  final TextEditingController controller;
  final void Function(Country) onCountrySelected;
  final void Function(String) onChanged;
  final void Function(String)? onSubmitted;

  @override
  State<_PhoneInput> createState() => _PhoneInputState();
}

class _PhoneInputState extends State<_PhoneInput> {
  final _selectorKey = GlobalKey();

  void _openPicker() {
    final box = _selectorKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final origin  = box.localToGlobal(Offset.zero, ancestor: overlay);

    showMenu<Country>(
      context: context,
      elevation: 4,
      color: KTokens.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KTokens.rMd)),
      position: RelativeRect.fromLTRB(
        origin.dx,
        origin.dy + box.size.height + 4,
        overlay.size.width - origin.dx - box.size.width,
        0,
      ),
      items: _countries.map((c) {
        final sel = c.isoCode == widget.country.isoCode;
        return PopupMenuItem<Country>(
          value: c,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(c.isoCode,
                  style: KTokens.tEyebrow.copyWith(color: KTokens.inkMuted)),
              const SizedBox(width: 8),
              Text(c.dialCode,
                  style: KTokens.tCta.copyWith(color: KTokens.ink)),
              const SizedBox(width: 6),
              Text(c.name,
                  style: KTokens.tHint.copyWith(color: KTokens.inkMuted)),
              if (sel) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check, size: 14, color: KTokens.accent),
              ],
            ],
          ),
        );
      }).toList(),
    ).then((result) {
      if (result != null) widget.onCountrySelected(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    const underline =
        UnderlineInputBorder(borderSide: BorderSide(color: KTokens.accent, width: 1.5));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tu número de WhatsApp', style: KTokens.tHint),
        const SizedBox(height: 8),
        Row(
          children: [
            // Country selector
            GestureDetector(
              key: _selectorKey,
              onTap: _openPicker,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.country.isoCode,
                      style: KTokens.tInput.copyWith(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text(widget.country.dialCode,
                      style: KTokens.tInput.copyWith(fontSize: 16)),
                  const Icon(Icons.arrow_drop_down,
                      size: 18, color: KTokens.inkMuted),
                ],
              ),
            ),
            // Vertical divider
            Container(
                width: 1,
                height: 22,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: KTokens.borderStrong),
            // Number field
            Expanded(
              child: TextField(
                controller: widget.controller,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                autofocus: true,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                cursorColor: KTokens.accent,
                cursorWidth: 2,
                style: KTokens.tInput.copyWith(fontSize: 18),
                decoration: InputDecoration(
                  hintText: '99 123 456',
                  hintStyle: KTokens.tInput.copyWith(
                      fontSize: 18, color: KTokens.inkPlaceholder),
                  border: underline,
                  enabledBorder: underline,
                  focusedBorder: underline,
                  contentPadding: const EdgeInsets.only(bottom: 8),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recibirás un código de 6 dígitos',
                style: KTokens.tMonoHint),
            Text('↵ enviar', style: KTokens.tMonoHint),
          ],
        ),
      ],
    );
  }
}

// ── Code input ────────────────────────────────────────────────────────────────

class _CodeInput extends StatelessWidget {
  const _CodeInput({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    const underline =
        UnderlineInputBorder(borderSide: BorderSide(color: KTokens.accent, width: 1.5));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Código de verificación', style: KTokens.tHint),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autofocus: true,
          maxLength: 6,
          cursorColor: KTokens.accent,
          cursorWidth: 2,
          style: KTokens.tInput.copyWith(letterSpacing: 8),
          decoration: InputDecoration(
            hintText: '• • • • • •',
            hintStyle: KTokens.tInput.copyWith(
                color: KTokens.inkPlaceholder, letterSpacing: 8),
            border: underline,
            enabledBorder: underline,
            focusedBorder: underline,
            contentPadding: const EdgeInsets.only(bottom: 8),
            isDense: true,
            counterText: '',
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('código de 6 dígitos', style: KTokens.tMonoHint),
            Text('↵ verificar',         style: KTokens.tMonoHint),
          ],
        ),
      ],
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.label,
    required this.enabled,
    required this.loading,
    required this.onPressed,
  });

  final String    label;
  final bool      enabled;
  final bool      loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.38,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: KTokens.ink,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(KTokens.rMd)),
          ),
          onPressed: onPressed,
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text('$label  →',
                  style: KTokens.tCta.copyWith(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

// ── Background decoration ─────────────────────────────────────────────────────

class _BackgroundCards extends StatelessWidget {
  const _BackgroundCards();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return Stack(children: [
          // Left column
          _card(left: -w * 0.12, top: h * 0.13, width: w * 0.30, height: 72),
          _card(left: -w * 0.06, top: h * 0.28, width: w * 0.34, height: 56),
          _card(left: -w * 0.14, top: h * 0.44, width: w * 0.28, height: 72),
          _card(left: -w * 0.08, top: h * 0.60, width: w * 0.32, height: 56),
          // Right column
          _card(right: -w * 0.10, top: h * 0.10, width: w * 0.32, height: 72),
          _card(right: -w * 0.06, top: h * 0.26, width: w * 0.30, height: 56),
          _card(right: -w * 0.12, top: h * 0.42, width: w * 0.34, height: 72),
          _card(right: -w * 0.08, top: h * 0.58, width: w * 0.28, height: 56),
          // Bottom row
          _card(left: w * 0.06,  bottom: h * 0.06, width: w * 0.26, height: 44),
          _card(right: w * 0.06, bottom: h * 0.03, width: w * 0.24, height: 44),
        ]);
      },
    );
  }

  Widget _card({
    double? left,
    double? right,
    double? top,
    double? bottom,
    required double width,
    required double height,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: KTokens.surface.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: KTokens.border),
        ),
      ),
    );
  }
}
