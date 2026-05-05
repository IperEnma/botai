import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/agenda/register_tenant.dart';
import '../../../providers/agenda/agenda_api_provider.dart';
import '../../../providers/agenda/agenda_user_provider.dart';
import '../../../providers/agenda/register_provider.dart';
import '../../../services/agenda_api_exception.dart';

const _kPrimary = Color(0xFF6366F1);
const _kAccent  = Color(0xFF8B5CF6);
const _kSurface = Color(0xFFF8FAFC);
const _kDark    = Color(0xFF0F172A);
const _kMuted   = Color(0xFF64748B);

// ── Step enum ─────────────────────────────────────────────────────────────────

enum _RegisterStep { initial, codeSent, verified }

// ── Country data ──────────────────────────────────────────────────────────────

class Country {
  const Country({
    required this.name,
    required this.dialCode,
    required this.flag,
    required this.minLength,
    required this.maxLength,
  });
  final String name;
  final String dialCode;
  final String flag;
  final int minLength;
  final int maxLength;
}

const _countries = [
  Country(name: 'Uruguay',   dialCode: '+598', flag: '🇺🇾', minLength: 8,  maxLength: 9),
  Country(name: 'Argentina', dialCode: '+54',  flag: '🇦🇷', minLength: 10, maxLength: 10),
  Country(name: 'Colombia',  dialCode: '+57',  flag: '🇨🇴', minLength: 10, maxLength: 10),
  Country(name: 'Venezuela', dialCode: '+58',  flag: '🇻🇪', minLength: 10, maxLength: 10),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _nombreCtrl   = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _codigoCtrl   = TextEditingController();
  final _passwordCtrl = TextEditingController();

  _RegisterStep _step        = _RegisterStep.initial;
  Country _selectedCountry   = _countries.first;
  String _phone              = '';
  bool _isPhoneValid         = false;
  String? _phoneError;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _codigoCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Teléfono ───────────────────────────────────────────────────────────────

  void _onPhoneChanged(String value) {
    final cleaned = value.replaceAll(RegExp(r'\D'), '');
    final full = '${_selectedCountry.dialCode}$cleaned';
    final valid = cleaned.length >= _selectedCountry.minLength &&
        cleaned.length <= _selectedCountry.maxLength;
    setState(() {
      _phone = full;
      _isPhoneValid = valid;
      _phoneError = valid ? null : 'Número inválido';
    });
  }

  // ── Acciones ───────────────────────────────────────────────────────────────

  void _sendCode() {
    if (!_formKey.currentState!.validate()) return;
    if (!_isPhoneValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresá un número válido')),
      );
      return;
    }
    setState(() => _step = _RegisterStep.codeSent);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Código enviado a $_phone'),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _validateCode() {
    if (!_formKey.currentState!.validate()) return;
    // Mock: cualquier código no vacío es válido.
    setState(() => _step = _RegisterStep.verified);
  }

  void _editNumber() {
    _codigoCtrl.clear();
    setState(() => _step = _RegisterStep.initial);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final RegisterTenantResponse? result =
        await ref.read(registerProvider.notifier).register(
      nombrePropietario: _nombreCtrl.text.trim(),
      email:             _emailCtrl.text.trim(),
      telefono:          _phone,
      nombreNegocio:     _nombreCtrl.text.trim(),
      categoriaSlug:     null,
    );
    if (result != null && mounted) {
      await ref
          .read(agendaUserProvider.notifier)
          .saveTenantId(result.tenantId);
      if (mounted) context.go('/agenda/onboarding');
    }
  }

  void _showLoginDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ingresar con código',
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _kDark)),
              const SizedBox(height: 12),
              Text(
                'Ingresá el código de 8 caracteres que recibiste al registrarte.',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: _kMuted, height: 1.5),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: ctrl,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                maxLength: 8,
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                    color: _kDark),
                decoration: InputDecoration(
                  labelText: 'Código de acceso',
                  hintText: 'K7MN2PQX',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: _kPrimary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text('Cancelar',
                        style:
                            GoogleFonts.poppins(color: _kMuted)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _kPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      final code =
                          ctrl.text.trim().toUpperCase();
                      if (code.length < 8) return;
                      Navigator.of(ctx).pop();
                      _loginWithCode(code);
                    },
                    child: Text('Ingresar',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loginWithCode(String accessCode) async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      final api = ref.read(agendaApiServiceProvider);
      final tenantId = await api.getTenantByCode(accessCode);
      if (!mounted) return;
      router.go('/agenda/tenants/$tenantId');
    } on AgendaApiException catch (e) {
      if (!mounted) return;
      final msg = e.status == 404
          ? 'Código no encontrado. Verificá que sea correcto.'
          : e.message;
      messenger.showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
      ));
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registerProvider);

    return Scaffold(
      backgroundColor: _kSurface,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _RegisterHero(
                  onBack: () =>
                      context.canPop() ? context.pop() : context.go('/agenda'),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildStepContent(state),

                        const SizedBox(height: 32),

                        _Divider(),
                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color: Colors.grey.shade300),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12)),
                              backgroundColor: Colors.white,
                            ),
                            onPressed: () =>
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(
                              content: Text(
                                  'Google Sign-In próximamente'),
                            )),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                const _GoogleIcon(),
                                const SizedBox(width: 10),
                                Text(
                                  'Continuar con Google',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: _kDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Center(
                          child: GestureDetector(
                            onTap: () => _showLoginDialog(context),
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.poppins(
                                    fontSize: 13, color: _kMuted),
                                children: [
                                  const TextSpan(
                                      text: '¿Ya tienes cuenta? '),
                                  TextSpan(
                                    text: 'Iniciar sesión',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: _kPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
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

  // ── Contenido según estado ─────────────────────────────────────────────────

  Widget _buildStepContent(RegisterState state) {
    return switch (_step) {
      _RegisterStep.initial   => _buildInitial(state),
      _RegisterStep.codeSent  => _buildCodeSent(state),
      _RegisterStep.verified  => _buildVerified(state),
    };
  }

  // ── INITIAL ────────────────────────────────────────────────────────────────

  Widget _buildInitial(RegisterState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        _Field(
          controller: _nombreCtrl,
          label: 'Nombre',
          hint: 'Tu nombre completo',
          icon: Icons.person_outline_rounded,
          validator: (v) =>
              (v?.trim().length ?? 0) < 2 ? 'Ingresá tu nombre' : null,
        ),
        const SizedBox(height: 14),
        _Field(
          controller: _emailCtrl,
          label: 'Email',
          hint: 'tu@email.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Ingresá tu email';
            if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
              return 'Email no válido';
            }
            return null;
          },
        ),
        const SizedBox(height: 14),
        PhoneInputField(
          country: _selectedCountry,
          controller: _phoneCtrl,
          onCountrySelected: (c) {
            setState(() => _selectedCountry = c);
            _onPhoneChanged(_phoneCtrl.text);
          },
          onChanged: _onPhoneChanged,
          error: _phoneError,
        ),
        const SizedBox(height: 24),
        _PrimaryButton(
          label: 'Enviar código',
          loading: false,
          onPressed: _sendCode,
        ),
      ],
    );
  }

  // ── CODE_SENT ──────────────────────────────────────────────────────────────

  Widget _buildCodeSent(RegisterState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Ícono + título
        Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sms_outlined,
                color: _kPrimary, size: 28),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Verifica tu número',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
              fontSize: 20, fontWeight: FontWeight.w700, color: _kDark),
        ),
        const SizedBox(height: 8),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.poppins(fontSize: 13, color: _kMuted),
            children: [
              const TextSpan(text: 'Te enviamos un código a '),
              TextSpan(
                text: _phone,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        _Field(
          controller: _codigoCtrl,
          label: 'Código de verificación',
          hint: 'Ingresá los dígitos recibidos',
          icon: Icons.dialpad_rounded,
          keyboardType: TextInputType.number,
          validator: (v) =>
              (v?.trim().isEmpty ?? true) ? 'Ingresá el código' : null,
        ),
        const SizedBox(height: 24),
        _PrimaryButton(
          label: 'Validar código',
          loading: false,
          onPressed: _validateCode,
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: _editNumber,
            child: Text(
              'Editar número',
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: _kMuted,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                  decorationColor: _kMuted),
            ),
          ),
        ),
      ],
    );
  }

  // ── VERIFIED ───────────────────────────────────────────────────────────────

  Widget _buildVerified(RegisterState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Ícono + título
        Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.verified_rounded,
                color: Colors.green.shade500, size: 30),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Cuenta verificada',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
              fontSize: 20, fontWeight: FontWeight.w700, color: _kDark),
        ),
        const SizedBox(height: 8),
        Text(
          'Ahora creá tu contraseña para acceder.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 13, color: _kMuted),
        ),
        const SizedBox(height: 28),
        _Field(
          controller: _passwordCtrl,
          label: 'Contraseña',
          hint: 'Mínimo 6 caracteres',
          icon: Icons.lock_outline_rounded,
          obscureText: true,
          validator: (v) => (v?.trim().length ?? 0) < 6
              ? 'Mínimo 6 caracteres'
              : null,
        ),
        const SizedBox(height: 24),
        if (state.error != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded,
                    color: Colors.red.shade500, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(state.error!,
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.red.shade700)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        _PrimaryButton(
          label: 'Continuar',
          loading: state.isLoading,
          onPressed: state.isLoading ? null : _submit,
        ),
      ],
    );
  }
}

// ── Hero ──────────────────────────────────────────────────────────────────────

class _RegisterHero extends StatelessWidget {
  const _RegisterHero({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kPrimary, _kAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 14,
        20,
        28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Crea tu cuenta',
                    style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 38),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Accedé a servicios o gestioná tu negocio.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.80),
                  height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Phone input field (controlled) ───────────────────────────────────────────

class PhoneInputField extends StatefulWidget {
  const PhoneInputField({
    super.key,
    required this.country,
    required this.controller,
    required this.onCountrySelected,
    required this.onChanged,
    this.error,
  });

  final Country country;
  final TextEditingController controller;
  final void Function(Country) onCountrySelected;
  final void Function(String) onChanged;
  final String? error;

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  final GlobalKey _selectorKey = GlobalKey();

  void _openDropdown() {
    final box =
        _selectorKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final origin = box.localToGlobal(Offset.zero, ancestor: overlay);

    showMenu<Country>(
      context: context,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      position: RelativeRect.fromLTRB(
        origin.dx,
        origin.dy + box.size.height,
        overlay.size.width - origin.dx - box.size.width,
        0,
      ),
      items: _countries.map((c) {
        final isSelected = c.dialCode == widget.country.dialCode;
        return PopupMenuItem<Country>(
          value: c,
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(c.flag, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 6),
              Text(c.dialCode,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kDark)),
              if (isSelected) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check_rounded,
                    size: 14, color: _kPrimary),
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
    return TextFormField(
      controller: widget.controller,
      keyboardType: TextInputType.phone,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: widget.onChanged,
      style: GoogleFonts.poppins(fontSize: 14, color: _kDark),
      decoration: InputDecoration(
        hintText: 'Número de WhatsApp',
        hintStyle: GoogleFonts.poppins(
            fontSize: 13, color: _kMuted.withValues(alpha: 0.6)),
        prefixIcon: GestureDetector(
          key: _selectorKey,
          onTap: _openDropdown,
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 12),
              Text(widget.country.flag,
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                widget.country.dialCode,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kDark,
                ),
              ),
              const Icon(Icons.arrow_drop_down, size: 18, color: _kMuted),
              const SizedBox(width: 8),
              Container(width: 1, height: 18, color: Colors.grey.shade300),
              const SizedBox(width: 4),
            ],
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        errorText: widget.error,
        errorStyle:
            GoogleFonts.poppins(fontSize: 12, color: Colors.red.shade600),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
      ),
    );
  }
}

// ── Form field ────────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.validator,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      obscureText: obscureText,
      style: GoogleFonts.poppins(fontSize: 14, color: _kDark),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.poppins(fontSize: 13, color: _kMuted),
        hintStyle: GoogleFonts.poppins(
            fontSize: 13, color: _kMuted.withValues(alpha: 0.6)),
        prefixIcon: Icon(icon, color: _kMuted, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.red.shade400, width: 2),
        ),
      ),
    );
  }
}

// ── Primary button ────────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: _kPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onPressed,
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Text(
                label,
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}

// ── Divider ───────────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade200)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('o',
              style: GoogleFonts.poppins(fontSize: 12, color: _kMuted)),
        ),
        Expanded(child: Divider(color: Colors.grey.shade200)),
      ],
    );
  }
}

// ── Google icon ───────────────────────────────────────────────────────────────

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Text(
          'G',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF4285F4),
          ),
        ),
      ),
    );
  }
}

