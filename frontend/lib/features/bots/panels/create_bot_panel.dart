import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/agenda/business.dart';
import '../../../providers/agenda/tenant/businesses_provider.dart';
import '../../agenda/register/konecta_tokens.dart';
import '../../../models/bot.dart' as api_bot;
import '../../../providers/bot_provider.dart';
import '../controllers/bots_controller.dart';
import '../models/bot.dart';
import '../widgets/capa_badge.dart';

// ─── Entry point ──────────────────────────────────────────────────────────────

Future<void> showCreateBotPanel(BuildContext context, {required String tenantId}) {
  return Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      barrierDismissible: true,
      pageBuilder: (ctx, a, b) => _CreateBotPanel(tenantId: tenantId),
      transitionsBuilder: (ctx, animation, b, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: child,
      ),
    ),
  );
}

// ─── Constants ────────────────────────────────────────────────────────────────

const _avatarIcons = ['◐', '◑', '◒', '◓', '★', '◆'];

const _avatarColors = [
  Color(0xFFA78BFA),
  Color(0xFF34D399),
  Color(0xFFFB923C),
  Color(0xFF60A5FA),
  Color(0xFFF472B6),
  Color(0xFFFBBF24),
];

List<String> _stepTitles(bool hasBizStep) => hasBizStep
    ? ['Sucursal', 'Identidad del bot', 'Qué sabe responder', 'Conectar WhatsApp']
    : ['Identidad del bot', 'Qué sabe responder', 'Conectar WhatsApp'];

List<String> _stepSubtitles(bool hasBizStep) => hasBizStep
    ? [
        '¿A qué sucursal pertenece este bot?',
        'Dale nombre, propósito y un avatar.',
        'Tu plan define qué tipo de respuestas puede dar.',
        'Ingresá las credenciales de tu cuenta Business.',
      ]
    : [
        'Dale nombre, propósito y un avatar.',
        'Tu plan define qué tipo de respuestas puede dar.',
        'Ingresá las credenciales de tu cuenta Business.',
      ];

// ─── Capa helpers ─────────────────────────────────────────────────────────────

int _capaIndex(BotCapa capa) => switch (capa) {
      BotCapa.capa1 => 0,
      BotCapa.capa2 => 1,
      BotCapa.capa3 => 2,
    };

bool _capaLocked(BotCapa capa, BotCapa planCapa) =>
    _capaIndex(capa) > _capaIndex(planCapa);

String _capaHeroTitle(BotCapa capa) => switch (capa) {
      BotCapa.capa1 => 'FAQ / Menús',
      BotCapa.capa2 => 'FAQ + IA con tu documentación',
      BotCapa.capa3 => 'CRM con acciones',
    };

String _capaHeroDesc(BotCapa capa) => switch (capa) {
      BotCapa.capa1 =>
        'Solo respuestas predefinidas. Ideal si tenés pocas preguntas frecuentes.',
      BotCapa.capa2 =>
        'Combiná respuestas predefinidas para lo común y dejá que la IA responda preguntas usando los documentos que cargues (RAG).',
      BotCapa.capa3 =>
        'IA + agendar, crear leads, gestionar clientes. Próximamente.',
    };

List<String> _capaBullets(BotCapa capa) => switch (capa) {
      BotCapa.capa1 => [
          'Menús y preguntas frecuentes exactas',
          'Respuestas rápidas y precisas',
        ],
      BotCapa.capa2 => [
          'Menús y respuestas predefinidas',
          'Búsqueda en tu documentación',
          'Derivación a humano si no sabe',
        ],
      BotCapa.capa3 => [
          'Todo lo de IA Híbrida',
          'Agendar turnos automáticamente',
          'Crear y gestionar leads',
        ],
    };

String _capaRowTitle(BotCapa capa) => switch (capa) {
      BotCapa.capa1 => 'Capa 1 · FAQ / Menús',
      BotCapa.capa2 => 'Capa 2 · IA Híbrida',
      BotCapa.capa3 => 'Capa 3 · CRM con acciones',
    };

String _capaRowDesc(BotCapa capa) => switch (capa) {
      BotCapa.capa1 =>
        'Solo respuestas predefinidas. Ideal si tenés pocas preguntas frecuentes.',
      BotCapa.capa2 => 'FAQ + IA con tu documentación (RAG).',
      BotCapa.capa3 => 'IA + agendar, crear leads, gestionar clientes.',
    };

String _capaNumber(BotCapa capa) => switch (capa) {
      BotCapa.capa1 => '1',
      BotCapa.capa2 => '2',
      BotCapa.capa3 => '3',
    };

// ─── Panel widget ─────────────────────────────────────────────────────────────

class _CreateBotPanel extends ConsumerStatefulWidget {
  const _CreateBotPanel({required this.tenantId});
  final String tenantId;

  @override
  ConsumerState<_CreateBotPanel> createState() => _CreateBotPanelState();
}

class _CreateBotPanelState extends ConsumerState<_CreateBotPanel> {
  int _step = 0;

  // Step 0
  late final TextEditingController _nameCtrl;
  late final TextEditingController _purposeCtrl;
  int _selectedAvatar = 0;

  // Step 1
  late BotCapa _capa;

  // Sucursales
  Set<String> _selectedBusinessIds = {};
  bool _autoSelected = false;

  // Step 2
  final TextEditingController _phoneIdCtrl = TextEditingController();
  final TextEditingController _accessTokenCtrl = TextEditingController();
  final TextEditingController _verifyTokenCtrl = TextEditingController();
  bool _obscureToken = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _capa = ref.read(businessPlanProvider).capa;
    _nameCtrl = TextEditingController();
    _purposeCtrl = TextEditingController();
    _nameCtrl.addListener(() => setState(() {}));
    _purposeCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _purposeCtrl.dispose();
    _phoneIdCtrl.dispose();
    _accessTokenCtrl.dispose();
    _verifyTokenCtrl.dispose();
    super.dispose();
  }

  bool _canProceedFor(bool hasBizStep) => switch (_step) {
        0 when hasBizStep => _selectedBusinessIds.isNotEmpty,
        0 => _nameCtrl.text.trim().isNotEmpty &&
            _purposeCtrl.text.trim().isNotEmpty,
        1 when hasBizStep => _nameCtrl.text.trim().isNotEmpty &&
            _purposeCtrl.text.trim().isNotEmpty,
        _ => true,
      };

  void _create() async {
    if (_isCreating) return;
    setState(() => _isCreating = true);

    final tier = tierFromCapa(_capa);
    final phoneId = _phoneIdCtrl.text.trim();
    final token = _accessTokenCtrl.text.trim();
    final verify = _verifyTokenCtrl.text.trim();

    final bot = api_bot.Bot(
      id: '',
      tenantId: widget.tenantId,
      name: _nameCtrl.text.trim(),
      description: _purposeCtrl.text.trim(),
      tier: tier,
      faqEnabled: true,
      aiEnabled: _capa != BotCapa.capa1,
      actionsEnabled: _capa == BotCapa.capa3,
      whatsappPhoneNumberId: phoneId.isEmpty ? null : phoneId,
      whatsappAccessToken: token.isEmpty ? null : token,
      whatsappVerifyToken: verify.isEmpty ? null : verify,
      linkedAgendaBusinessIds: _selectedBusinessIds.toList(),
      createdAt: DateTime.now(),
    );

    final result = await ref.read(botsProvider.notifier).createBot(bot);
    if (!mounted) return;
    if (result == null) {
      final error = ref.read(botsProvider).error ?? 'Error al crear el bot';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red.shade700),
      );
      setState(() => _isCreating = false);
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bizState = ref.watch(businessesProvider(widget.tenantId));
    final businesses = bizState.items;

    // Auto-select when there's exactly one business
    if (!_autoSelected && !bizState.isLoading && businesses.length == 1) {
      _autoSelected = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedBusinessIds = {businesses.first.id});
      });
    } else if (!_autoSelected && !bizState.isLoading && businesses.length > 1) {
      _autoSelected = true;
    }

    final hasBizStep = businesses.length > 1;
    final totalSteps = hasBizStep ? 4 : 3;
    final lastStep = totalSteps - 1;
    final titles = _stepTitles(hasBizStep);
    final subtitles = _stepSubtitles(hasBizStep);
    final canProceed = _canProceedFor(hasBizStep);

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: const Color(0xFFFBFAF7),
        child: SizedBox(
          width: 480,
          height: double.infinity,
          child: Column(
            children: [
              _PanelHeader(
                step: _step,
                totalSteps: totalSteps,
                title: titles[_step],
                subtitle: subtitles[_step],
                onClose: () => Navigator.pop(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: _buildStep(hasBizStep, businesses),
                ),
              ),
              _PanelFooter(
                isCreating: _isCreating,
                canProceed: canProceed,
                onBack: _step > 0 ? () => setState(() => _step--) : null,
                onNext: _step < lastStep
                    ? () {
                        if (canProceed) setState(() => _step++);
                      }
                    : null,
                onCreate: _step == lastStep ? _create : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(bool hasBizStep, List<Business> businesses) {
    if (hasBizStep && _step == 0) {
      return _StepSucursal(
        businesses: businesses,
        selected: _selectedBusinessIds,
        onToggle: (id, sel) => setState(() {
          if (sel) {
            _selectedBusinessIds.add(id);
          } else {
            _selectedBusinessIds.remove(id);
          }
        }),
      );
    }
    final identidadStep = hasBizStep ? 1 : 0;
    final conocimientoStep = hasBizStep ? 2 : 1;
    if (_step == identidadStep) {
      return _StepIdentidad(
        nameCtrl: _nameCtrl,
        purposeCtrl: _purposeCtrl,
        selectedAvatar: _selectedAvatar,
        onAvatarChanged: (v) => setState(() => _selectedAvatar = v),
      );
    }
    if (_step == conocimientoStep) {
      return _StepConocimiento(
        capa: _capa,
        planCapa: ref.read(businessPlanProvider).capa,
        onCapaChanged: (v) => setState(() => _capa = v),
      );
    }
    return _StepCanales(
      phoneIdCtrl: _phoneIdCtrl,
      accessTokenCtrl: _accessTokenCtrl,
      verifyTokenCtrl: _verifyTokenCtrl,
      obscureToken: _obscureToken,
      onToggleObscure: () => setState(() => _obscureToken = !_obscureToken),
    );
  }
}

// ─── Panel header ─────────────────────────────────────────────────────────────

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.step,
    required this.totalSteps,
    required this.title,
    required this.subtitle,
    required this.onClose,
  });
  final int step;
  final int totalSteps;
  final String title;
  final String subtitle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final stepLabel =
        'PASO ${(step + 1).toString().padLeft(2, '0')} DE ${totalSteps.toString().padLeft(2, '0')}';
    return Container(
      color: KTokens.surface,
      padding: EdgeInsets.fromLTRB(28, topPad + 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NUEVO BOT',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        color: KTokens.inkSoft,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: KTokens.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: KTokens.inkMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, size: 18),
                color: KTokens.inkSoft,
                splashRadius: 18,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ProgressBar(step: step, totalSteps: totalSteps),
          const SizedBox(height: 8),
          Text(
            stepLabel,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              color: KTokens.inkSoft,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: KTokens.border),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.step, required this.totalSteps});
  final int step;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < totalSteps; i++) ...[
          if (i > 0) const SizedBox(width: 5),
          Expanded(
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: i <= step ? KTokens.accent : const Color(0xFFE5E3DF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Panel footer ─────────────────────────────────────────────────────────────

class _PanelFooter extends StatelessWidget {
  const _PanelFooter({
    required this.canProceed,
    required this.isCreating,
    this.onBack,
    this.onNext,
    this.onCreate,
  });

  final bool canProceed;
  final bool isCreating;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(28, 16, 28, 16 + bottomPad),
      decoration: const BoxDecoration(
        color: KTokens.surface,
        border: Border(top: BorderSide(color: KTokens.border)),
      ),
      child: Row(
        children: [
          if (onBack != null)
            TextButton(
              onPressed: onBack,
              style: TextButton.styleFrom(foregroundColor: KTokens.inkMuted),
              child: Text(
                '← Atrás',
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          const Spacer(),
          if (onNext != null)
            ElevatedButton(
              onPressed: canProceed ? onNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: KTokens.ink,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE5E3DF),
                disabledForegroundColor: KTokens.inkSoft,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(KTokens.rSm),
                ),
                textStyle: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500),
              ),
              child: const Text('Continuar →'),
            ),
          if (onCreate != null)
            ElevatedButton(
              onPressed: isCreating ? null : onCreate,
              style: ElevatedButton.styleFrom(
                backgroundColor: KTokens.ink,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE5E3DF),
                disabledForegroundColor: KTokens.inkSoft,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(KTokens.rSm),
                ),
                textStyle: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500),
              ),
              child: isCreating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Crear bot →'),
            ),
        ],
      ),
    );
  }
}

// ─── Step 0: Identidad ────────────────────────────────────────────────────────

class _StepIdentidad extends StatelessWidget {
  const _StepIdentidad({
    required this.nameCtrl,
    required this.purposeCtrl,
    required this.selectedAvatar,
    required this.onAvatarChanged,
  });

  final TextEditingController nameCtrl;
  final TextEditingController purposeCtrl;
  final int selectedAvatar;
  final ValueChanged<int> onAvatarChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Quién va a responder?',
          style: GoogleFonts.playfairDisplay(
            fontSize: 26,
            fontStyle: FontStyle.italic,
            color: KTokens.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Pensá en tu bot como un miembro virtual del equipo. Dale un nombre que el cliente vea cuando le hable.',
          style: GoogleFonts.inter(
              fontSize: 13, color: KTokens.inkMuted, height: 1.5),
        ),
        const SizedBox(height: 28),
        Text(
          'NOMBRE DEL BOT',
          style: GoogleFonts.jetBrainsMono(
              fontSize: 10, color: KTokens.inkSoft, letterSpacing: 0.8),
        ),
        const SizedBox(height: 8),
        _UnderlineTextField(
            controller: nameCtrl, hint: 'ej. Reservas, Recepción...'),
        const SizedBox(height: 20),
        Text(
          'DESCRIPCIÓN',
          style: GoogleFonts.jetBrainsMono(
              fontSize: 10, color: KTokens.inkSoft, letterSpacing: 0.8),
        ),
        const SizedBox(height: 8),
        _BoxTextField(
          controller: purposeCtrl,
          hint: 'Toma datos del cliente, consulta la agenda y confirma turnos. Si no entiende, deriva a un humano.',
          maxLines: 4,
        ),
        const SizedBox(height: 28),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'AVATAR',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  color: KTokens.inkSoft,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.8,
                ),
              ),
              TextSpan(
                text: ' · se ve en la conversación',
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 10, color: KTokens.inkSoft),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _AvatarPicker(selected: selectedAvatar, onChanged: onAvatarChanged),
      ],
    );
  }
}

// ─── Step 1: Conocimiento ─────────────────────────────────────────────────────

class _StepConocimiento extends StatelessWidget {
  const _StepConocimiento({
    required this.capa,
    required this.planCapa,
    required this.onCapaChanged,
  });

  final BotCapa capa;
  final BotCapa planCapa;
  final ValueChanged<BotCapa> onCapaChanged;

  @override
  Widget build(BuildContext context) {
    final otherCapas = BotCapa.values.where((c) => c != capa).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CapaHeroCard(capa: capa, planCapa: planCapa),
        for (final other in otherCapas) ...[
          const SizedBox(height: 10),
          _CapaCompactRow(
            capa: other,
            planCapa: planCapa,
            onTap: _capaLocked(other, planCapa)
                ? null
                : () => onCapaChanged(other),
          ),
        ],
      ],
    );
  }
}

// ─── Step 2: Canales / WhatsApp ───────────────────────────────────────────────

class _StepCanales extends StatelessWidget {
  const _StepCanales({
    required this.phoneIdCtrl,
    required this.accessTokenCtrl,
    required this.verifyTokenCtrl,
    required this.obscureToken,
    required this.onToggleObscure,
  });

  final TextEditingController phoneIdCtrl;
  final TextEditingController accessTokenCtrl;
  final TextEditingController verifyTokenCtrl;
  final bool obscureToken;
  final VoidCallback onToggleObscure;

  static const _webhookUrl = 'https://tu-dominio.com/webhook/whatsapp';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tutorial card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: KTokens.accentSoft,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: KTokens.accent.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: KTokens.accent),
                  const SizedBox(width: 8),
                  Text(
                    '¿Cómo obtener las credenciales?',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: KTokens.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '1. Ve a developers.facebook.com\n'
                '2. Crea una app de tipo "Business"\n'
                '3. Agrega el producto "WhatsApp"\n'
                '4. En WhatsApp › API Setup encontrarás Phone Number ID y Access Token\n'
                '5. Configura el Webhook con la URL de abajo y el Verify Token',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: KTokens.ink,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Phone Number ID
        Text(
          'PHONE NUMBER ID',
          style: GoogleFonts.jetBrainsMono(
              fontSize: 10, color: KTokens.inkSoft, letterSpacing: 0.8),
        ),
        const SizedBox(height: 8),
        _UnderlineTextField(
            controller: phoneIdCtrl, hint: 'Ej: 1234567890123456'),
        const SizedBox(height: 20),

        // Access Token
        Text(
          'ACCESS TOKEN',
          style: GoogleFonts.jetBrainsMono(
              fontSize: 10, color: KTokens.inkSoft, letterSpacing: 0.8),
        ),
        const SizedBox(height: 8),
        _AccessTokenField(
          controller: accessTokenCtrl,
          obscure: obscureToken,
          onToggle: onToggleObscure,
        ),
        const SizedBox(height: 20),

        // Verify Token
        Text(
          'VERIFY TOKEN',
          style: GoogleFonts.jetBrainsMono(
              fontSize: 10, color: KTokens.inkSoft, letterSpacing: 0.8),
        ),
        const SizedBox(height: 8),
        _UnderlineTextField(
          controller: verifyTokenCtrl,
          hint: 'Token secreto que vos inventás para verificar el webhook',
        ),
        const SizedBox(height: 24),

        // Webhook URL
        Text(
          'URL DEL WEBHOOK',
          style: GoogleFonts.jetBrainsMono(
              fontSize: 10, color: KTokens.inkSoft, letterSpacing: 0.8),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          decoration: BoxDecoration(
            color: KTokens.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: KTokens.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: SelectableText(
                  _webhookUrl,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    color: KTokens.ink,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 16, color: KTokens.inkSoft),
                splashRadius: 16,
                tooltip: 'Copiar',
                onPressed: () {
                  Clipboard.setData(const ClipboardData(text: _webhookUrl));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('URL copiada'),
                        duration: Duration(seconds: 2)),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Pegá esta URL en Meta for Developers › WhatsApp › Configuration › Webhook. Usá el mismo Verify Token de arriba.',
          style: GoogleFonts.inter(
              fontSize: 12, color: KTokens.inkMuted, height: 1.5),
        ),
        const SizedBox(height: 16),

        // Skip hint
        Center(
          child: Text(
            'Podés completar esto después desde la configuración del bot.',
            style: GoogleFonts.inter(fontSize: 12, color: KTokens.inkSoft),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

// ─── Shared field widgets ─────────────────────────────────────────────────────

class _UnderlineTextField extends StatelessWidget {
  const _UnderlineTextField({required this.controller, required this.hint});
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: GoogleFonts.inter(fontSize: 15, color: KTokens.ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 15, color: KTokens.inkSoft),
        border: const UnderlineInputBorder(
            borderSide: BorderSide(color: KTokens.border)),
        enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: KTokens.border)),
        focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: KTokens.accent, width: 2)),
        contentPadding: const EdgeInsets.only(bottom: 8),
      ),
    );
  }
}

class _BoxTextField extends StatelessWidget {
  const _BoxTextField(
      {required this.controller, required this.hint, this.maxLines = 1});
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.inter(fontSize: 14, color: KTokens.ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.inter(fontSize: 14, color: KTokens.inkSoft),
        filled: true,
        fillColor: KTokens.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: KTokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: KTokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: KTokens.accent, width: 1.5),
        ),
      ),
    );
  }
}

class _AccessTokenField extends StatelessWidget {
  const _AccessTokenField({
    required this.controller,
    required this.obscure,
    required this.onToggle,
  });
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: GoogleFonts.inter(fontSize: 14, color: KTokens.ink),
      decoration: InputDecoration(
        hintText: 'EAAxxxxxxx...',
        hintStyle:
            GoogleFonts.inter(fontSize: 14, color: KTokens.inkSoft),
        filled: true,
        fillColor: KTokens.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: KTokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: KTokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: KTokens.accent, width: 1.5),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 18,
            color: KTokens.inkSoft,
          ),
          splashRadius: 18,
          onPressed: onToggle,
        ),
      ),
    );
  }
}

// ─── Avatar picker ────────────────────────────────────────────────────────────

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({required this.selected, required this.onChanged});
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < _avatarIcons.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          GestureDetector(
            onTap: () => onChanged(i),
            child: i == selected
                ? Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      border: Border.all(color: KTokens.accent, width: 2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _avatarColors[i],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(_avatarIcons[i],
                            style: const TextStyle(
                                fontSize: 20, color: Colors.white)),
                      ),
                    ),
                  )
                : Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _avatarColors[i],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(_avatarIcons[i],
                          style: const TextStyle(
                              fontSize: 20, color: Colors.white)),
                    ),
                  ),
          ),
        ],
      ],
    );
  }
}

// ─── Capa cards ───────────────────────────────────────────────────────────────

class _CapaHeroCard extends StatelessWidget {
  const _CapaHeroCard({required this.capa, required this.planCapa});
  final BotCapa capa;
  final BotCapa planCapa;

  @override
  Widget build(BuildContext context) {
    final isMyCapa = capa == planCapa;
    final bullets = _capaBullets(capa);
    return Container(
      decoration: BoxDecoration(
        color: KTokens.accentSoft,
        border: Border.all(color: KTokens.accent, width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CapaBadge(capa: capa),
              const SizedBox(width: 8),
              if (isMyCapa)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: KTokens.accentSoft,
                    border: Border.all(color: KTokens.accent),
                    borderRadius: BorderRadius.circular(KTokens.rPill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: KTokens.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'TU PLAN',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: KTokens.accent,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _capaHeroTitle(capa),
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontStyle: FontStyle.italic,
              color: KTokens.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _capaHeroDesc(capa),
            style: GoogleFonts.inter(
              fontSize: 13,
              color: KTokens.inkMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          for (final bullet in bullets) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle, size: 15, color: KTokens.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(bullet,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: KTokens.ink)),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _CapaCompactRow extends StatelessWidget {
  const _CapaCompactRow({
    required this.capa,
    required this.planCapa,
    this.onTap,
  });

  final BotCapa capa;
  final BotCapa planCapa;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final locked = _capaLocked(capa, planCapa);
    final isMyCapa = capa == planCapa;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: KTokens.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: KTokens.border),
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                color: Color(0xFFECEAE5),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _capaNumber(capa),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: KTokens.inkMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _capaRowTitle(capa),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: KTokens.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _capaRowDesc(capa),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: KTokens.inkMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (isMyCapa)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: KTokens.accentSoft,
                  border: Border.all(color: KTokens.accent),
                  borderRadius: BorderRadius.circular(KTokens.rPill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: KTokens.accent, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'TU PLAN',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: KTokens.accent,
                      ),
                    ),
                  ],
                ),
              )
            else if (locked)
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: KTokens.accent,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w500),
                ),
                child: const Text('Mejorar plan →'),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Step: Sucursal selection (only when tenant has >1 business) ──────────────

class _StepSucursal extends StatelessWidget {
  const _StepSucursal({
    required this.businesses,
    required this.selected,
    required this.onToggle,
  });

  final List<Business> businesses;
  final Set<String> selected;
  final void Function(String id, bool selected) onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿A qué sucursal va este bot?',
          style: GoogleFonts.playfairDisplay(
            fontSize: 26,
            fontStyle: FontStyle.italic,
            color: KTokens.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'El bot solo gestionará turnos y consultas de las sucursales que seleccionés acá.',
          style: GoogleFonts.inter(
              fontSize: 13, color: KTokens.inkMuted, height: 1.5),
        ),
        const SizedBox(height: 24),
        for (final biz in businesses) ...[
          _BizTile(
            business: biz,
            isSelected: selected.contains(biz.id),
            onTap: () => onToggle(biz.id, !selected.contains(biz.id)),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _BizTile extends StatelessWidget {
  const _BizTile({
    required this.business,
    required this.isSelected,
    required this.onTap,
  });

  final Business business;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: isSelected ? KTokens.accentSoft : KTokens.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? KTokens.accent : KTokens.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? KTokens.accent.withValues(alpha: 0.15)
                    : const Color(0xFFECEAE5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  business.nombre.isNotEmpty
                      ? business.nombre[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? KTokens.accent : KTokens.inkMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                business.nombre,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: KTokens.ink,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: KTokens.accent, size: 20)
            else
              Icon(Icons.radio_button_unchecked,
                  color: KTokens.inkSoft.withValues(alpha: 0.5), size: 20),
          ],
        ),
      ),
    );
  }
}
