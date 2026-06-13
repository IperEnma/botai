import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/agenda/agenda_service.dart';
import '../../../../models/agenda/tenant_invitation.dart';
import '../../../../providers/agenda/tenant/business_staff_provider.dart';
import '../../../../providers/agenda/tenant/services_provider.dart';
import '../../../../widgets/agenda_phone_field.dart';
import '../../register/konecta_tokens.dart';
import '../models/member.dart';
import '../providers/equipo_provider.dart';

Future<void> showAddMemberPanel(
    BuildContext context, EquipoKey key) {
  return Navigator.of(context).push<void>(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      barrierDismissible: true,
      pageBuilder: (_, _, _) => AddMemberPanel(equipoKey: key),
      transitionsBuilder: (_, animation, _, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        );
      },
    ),
  );
}

/// Panel de creación de miembro.
///
/// [embedMode] = true → se omite el wrapper Align/SizedBox (para embeberlo
/// dentro de otro panel). [onDone]/[onCancel] reemplazan Navigator.pop()
/// cuando se proveen.
class AddMemberPanel extends ConsumerStatefulWidget {
  const AddMemberPanel({
    super.key,
    required this.equipoKey,
    this.onDone,
    this.onCancel,
    this.embedMode = false,
  });

  final EquipoKey equipoKey;
  final VoidCallback? onDone;
  final VoidCallback? onCancel;
  final bool embedMode;

  @override
  ConsumerState<AddMemberPanel> createState() => _AddMemberPanelState();
}

class _AddMemberPanelState extends ConsumerState<AddMemberPanel> {
  int _step = 0;
  bool _isCreating = false;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  MemberType _selectedType = MemberType.profesionalSoloPerfil;
  Color _selectedColor = KTokens.proPalette[0];
  final Set<String> _selectedServices = {};

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  bool get _typeRequiresAccount =>
      _selectedType == MemberType.profesionalConCuenta ||
      _selectedType == MemberType.profesionalSoloLectura ||
      _selectedType == MemberType.recepcion;

  /// Recepción no ofrece servicios ni necesita color en el calendario:
  /// salta el paso "¿Qué hace?" (color + servicios).
  bool get _typeOffersServices => _selectedType != MemberType.recepcion;

  int get _totalSteps => _typeOffersServices ? 3 : 2;

  void _next() {
    final lastStep = _totalSteps - 1;
    if (_step < lastStep) {
      setState(() => _step++);
    } else {
      _create();
    }
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  void _dismiss() {
    if (widget.onCancel != null) {
      widget.onCancel!();
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    // Para "con cuenta" / "recepción" exigimos email.
    final email = _emailCtrl.text.trim();
    if (_typeRequiresAccount) {
      if (email.isEmpty || !email.contains('@')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'El email es obligatorio para "Con cuenta" y "Recepción".',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
            ),
            backgroundColor: KTokens.excClosed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(KTokens.rSm)),
          ),
        );
        return;
      }
    }

    final phone = _phoneCtrl.text.trim();
    if (phone.isNotEmpty) {
      final staffKey = (
        tenantId: widget.equipoKey.tenantId,
        businessId: widget.equipoKey.businessId,
      );
      final currentMembers = ref.read(businessStaffProvider(staffKey)).members;
      final normalized = phone.replaceAll(RegExp(r'\D'), '');
      final duplicate = currentMembers.any((m) {
        final mt = m.telefono?.replaceAll(RegExp(r'\D'), '') ?? '';
        return mt.isNotEmpty && mt == normalized;
      });
      if (duplicate) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ya existe un miembro con ese número de WhatsApp.',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
            ),
            backgroundColor: KTokens.excClosed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(KTokens.rSm)),
          ),
        );
        return;
      }
    }

    final rol = switch (_selectedType) {
      MemberType.recepcion => 'Recepcionista',
      MemberType.profesionalSoloPerfil => 'Profesional',
      MemberType.profesionalConCuenta => 'Profesional',
      MemberType.profesionalSoloLectura => 'Profesional',
    };

    setState(() => _isCreating = true);

    final staffKey = (
      tenantId: widget.equipoKey.tenantId,
      businessId: widget.equipoKey.businessId,
    );
    final notifier = ref.read(businessStaffProvider(staffKey).notifier);

    final colorHex =
        '#${(_selectedColor.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

    // Ruteo por tipo:
    // - solo perfil → POST /staff (sin User, sin rol RBAC)
    // - con cuenta / recepción → POST /tenant/invitations (crea User + rol RBAC)
    bool ok;
    String? createdId;
    if (_typeRequiresAccount) {
      final inviteRole = switch (_selectedType) {
        MemberType.recepcion => 'RECEPTION',
        MemberType.profesionalSoloLectura => 'STAFF_VIEWER',
        _ => 'STAFF_OPERATOR',
      };
      final inv = await notifier.inviteMember(CreateTenantInvitationRequest(
        nombre: name,
        email: email,
        telefono: phone.isEmpty ? null : phone,
        role: inviteRole,
        businessIds: [widget.equipoKey.businessId],
      ));
      ok = inv != null;
      createdId = inv?.staffMemberId;
    } else {
      final created = await notifier.addMember(
        name,
        rol,
        null,
        telefono: phone.isEmpty ? null : phone,
        color: colorHex,
      );
      ok = created != null;
      createdId = created?.id;
    }

    if (!mounted) return;

    if (ok) {
      if (_selectedServices.isNotEmpty && createdId != null) {
        try {
          await notifier.updateMemberServices(
              createdId, _selectedServices.toList());
        } catch (_) {}
      }
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _typeRequiresAccount
                ? 'Invitación creada. El miembro ya puede ingresar con Google usando $email.'
                : 'Miembro creado correctamente.',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
          ),
          backgroundColor: KTokens.accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(KTokens.rSm)),
        ),
      );

      if (widget.onDone != null) {
        widget.onDone!();
      } else {
        Navigator.of(context).pop();
      }
    } else {
      setState(() => _isCreating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo crear el miembro. Intentá de nuevo.',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
          ),
          backgroundColor: KTokens.excClosed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(KTokens.rSm)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mantener vivo businessStaffProvider mientras este panel está montado.
    // En el flujo Equipo, EquipoNotifier ya lo mantiene vivo vía ref.listen.
    // En el flujo Servicio, nada lo escucha, y al ser .autoDispose el
    // StateNotifier puede ser disposed durante el await del addMember,
    // produciendo StateError al intentar setear state tras la respuesta —
    // eso es lo que hacía caer la creación en el flujo Servicio.
    ref.watch(businessStaffProvider((
      tenantId: widget.equipoKey.tenantId,
      businessId: widget.equipoKey.businessId,
    )));

    final servicesState = ref.watch(
      servicesProvider((
        tenantId: widget.equipoKey.tenantId,
        businessId: widget.equipoKey.businessId,
      )),
    );
    final services = servicesState.items.where((s) => s.activo).toList();

    final content = Material(
      color: Colors.white,
      elevation: 0,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: KTokens.border)),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProgressBar(step: _step, total: _totalSteps),
                    const SizedBox(height: 8),
                    Text(
                      'PASO 0${_step + 1} DE 0$_totalSteps',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        color: KTokens.inkSoft,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'NUEVO MIEMBRO',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        color: KTokens.accent,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _stepTitle(),
                      style: KTokens.tHero,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _stepSubtitle(),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: KTokens.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _StepContent(
                      step: _step,
                      nameCtrl: _nameCtrl,
                      phoneCtrl: _phoneCtrl,
                      emailCtrl: _emailCtrl,
                      selectedType: _selectedType,
                      selectedColor: _selectedColor,
                      selectedServices: _selectedServices,
                      services: services,
                      emailRequired: _typeRequiresAccount,
                      onTypeChanged: (t) => setState(() => _selectedType = t),
                      onColorChanged: (c) => setState(() => _selectedColor = c),
                      onServiceToggled: (id) => setState(() {
                        if (_selectedServices.contains(id)) {
                          _selectedServices.remove(id);
                        } else {
                          _selectedServices.add(id);
                        }
                      }),
                    ),
                  ],
                ),
              ),
            ),
            _Footer(
              step: _step,
              totalSteps: _totalSteps,
              isCreating: _isCreating,
              onBack: _back,
              onNext: _next,
              onCancel: _dismiss,
            ),
          ],
        ),
      ),
    );

    if (widget.embedMode) return content;

    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(width: 480, child: content),
    );
  }

  String _stepTitle() => switch (_step) {
        0 => '¿Quién es?',
        1 => '¿Qué rol tiene?',
        _ => '¿Qué hace?',
      };

  String _stepSubtitle() => switch (_step) {
        0 => 'Datos básicos del nuevo miembro.',
        1 => 'El rol define lo que puede ver y hacer.',
        _ => 'Color de agenda y servicios que realiza (opcional; también se asignan desde Servicios).',
      };
}

// ─── Progress bar ─────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.step, required this.total});
  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final isDone = i < step;
        final isCurrent = i == step;
        return Expanded(
          child: Container(
            height: 3,
            margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
            decoration: BoxDecoration(
              color: (isDone || isCurrent) ? KTokens.accent : KTokens.border,
              borderRadius: BorderRadius.circular(KTokens.rPill),
            ),
          ),
        );
      }),
    );
  }
}

// ─── Step content ─────────────────────────────────────────────────────────────

class _StepContent extends StatelessWidget {
  const _StepContent({
    required this.step,
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.emailCtrl,
    required this.selectedType,
    required this.selectedColor,
    required this.selectedServices,
    required this.services,
    required this.emailRequired,
    required this.onTypeChanged,
    required this.onColorChanged,
    required this.onServiceToggled,
  });

  final int step;
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController emailCtrl;
  final MemberType selectedType;
  final Color selectedColor;
  final Set<String> selectedServices;
  final List<AgendaService> services;
  final bool emailRequired;
  final ValueChanged<MemberType> onTypeChanged;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<String> onServiceToggled;

  @override
  Widget build(BuildContext context) {
    return switch (step) {
      0 => _Step1(
          nameCtrl: nameCtrl,
          phoneCtrl: phoneCtrl,
          emailCtrl: emailCtrl,
          emailRequired: emailRequired,
        ),
      1 => _Step2(selected: selectedType, onChanged: onTypeChanged),
      _ => _Step3(
          selectedColor: selectedColor,
          selectedServices: selectedServices,
          services: services,
          onColorChanged: onColorChanged,
          onServiceToggled: onServiceToggled,
        ),
    };
  }
}

// Step 1: Name + phone + email
class _Step1 extends StatelessWidget {
  const _Step1({
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.emailCtrl,
    required this.emailRequired,
  });
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController emailCtrl;

  /// Pista de UX: el email es obligatorio solo cuando el tipo elegido requiere
  /// cuenta (Profesional con cuenta / Recepción). Como el tipo se elige en
  /// step 2, mostramos el campo siempre y le cambiamos el label / hint.
  final bool emailRequired;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LineInput(controller: nameCtrl, hint: 'NOMBRE COMPLETO'),
        const SizedBox(height: 24),
        AgendaPhoneField(
          controller: phoneCtrl,
          required: false,
          label: 'WHATSAPP',
          labelStyle: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            color: KTokens.inkSoft,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 24),
        _LineInput(
          controller: emailCtrl,
          hint: emailRequired
              ? 'EMAIL · OBLIGATORIO PARA CON CUENTA / RECEPCIÓN'
              : 'EMAIL (OPCIONAL · SOLO SI VA A INICIAR SESIÓN)',
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }
}

class _LineInput extends StatelessWidget {
  const _LineInput({
    required this.controller,
    required this.hint,
    this.keyboardType,
  });
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hint,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            color: KTokens.inkSoft,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: KTokens.ink,
          ),
          decoration: const InputDecoration(
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: KTokens.border, width: 1.5),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: KTokens.accent, width: 1.5),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: KTokens.border, width: 1.5),
            ),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ],
    );
  }
}

// Step 2: Type selection
class _Step2 extends StatelessWidget {
  const _Step2({required this.selected, required this.onChanged});
  final MemberType selected;
  final ValueChanged<MemberType> onChanged;

  @override
  Widget build(BuildContext context) {
    // (type, label, description, comingSoon)
    final types = [
      (
        MemberType.profesionalSoloPerfil,
        'Profesional solo perfil',
        'Aparece en la agenda pero no puede iniciar sesión.',
        false,
      ),
      (
        MemberType.profesionalConCuenta,
        'Profesional con cuenta',
        'Puede iniciar sesión y gestionar su agenda.',
        false,
      ),
      (
        MemberType.profesionalSoloLectura,
        'Profesional solo lectura',
        'Inicia sesión pero solo consulta su agenda y horarios.',
        false,
      ),
      (
        MemberType.recepcion,
        'Recepción con cuenta',
        'Puede gestionar cualquier turno del negocio.',
        false,
      ),
    ];

    return Column(
      children: types.map((t) {
        final (type, name, desc, comingSoon) = t;
        final isActive = selected == type;
        return Opacity(
          opacity: comingSoon ? 0.45 : 1.0,
          child: GestureDetector(
            onTap: comingSoon ? null : () => onChanged(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isActive ? KTokens.accentSoft : KTokens.surface,
                border: Border.all(
                  color: isActive ? KTokens.accent : KTokens.border,
                  width: isActive ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(KTokens.rSm),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isActive ? KTokens.accent : KTokens.ink,
                              ),
                            ),
                            if (comingSoon) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: KTokens.inkSoft,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'PRÓXIMAMENTE',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 9,
                                    color: Colors.white,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          desc,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color:
                                isActive ? KTokens.accent : KTokens.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isActive)
                    const Icon(Icons.check_circle_rounded,
                        color: KTokens.accent, size: 20),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// Step 3: Color + services
class _Step3 extends StatelessWidget {
  const _Step3({
    required this.selectedColor,
    required this.selectedServices,
    required this.services,
    required this.onColorChanged,
    required this.onServiceToggled,
  });

  final Color selectedColor;
  final Set<String> selectedServices;
  final List<AgendaService> services;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<String> onServiceToggled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'COLOR IDENTIFICADOR',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            color: KTokens.inkSoft,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: KTokens.proPalette.map((c) {
            final isSelected = c == selectedColor;
            return GestureDetector(
              onTap: () => onColorChanged(c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: KTokens.accent, width: 2.5)
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text(
          'SERVICIOS QUE OFRECE',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            color: KTokens.inkSoft,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        if (services.isEmpty)
          Text(
            'No hay servicios activos en este negocio.',
            style: GoogleFonts.inter(fontSize: 13, color: KTokens.inkMuted),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: services.map((s) {
              final isSelected = selectedServices.contains(s.id);
              return GestureDetector(
                onTap: () => onServiceToggled(s.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? KTokens.accentSoft
                        : const Color(0x0C000000),
                    border: Border.all(
                      color: isSelected ? KTokens.accent : Colors.transparent,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    s.nombre,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isSelected ? KTokens.accent : KTokens.inkMuted,
                      fontWeight: isSelected
                          ? FontWeight.w500
                          : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        if (selectedServices.isNotEmpty) ...[
          const SizedBox(height: 20),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: KTokens.accentSoft,
              border:
                  Border.all(color: KTokens.accent.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(KTokens.rSm),
            ),
            child: Text(
              '${selectedServices.length} servicio${selectedServices.length > 1 ? 's' : ''} seleccionado${selectedServices.length > 1 ? 's' : ''}',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: KTokens.accent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Footer ───────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer({
    required this.step,
    required this.totalSteps,
    required this.isCreating,
    required this.onBack,
    required this.onNext,
    required this.onCancel,
  });

  final int step;
  final int totalSteps;
  final bool isCreating;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: KTokens.border)),
      ),
      child: Row(
        children: [
          if (step == 0)
            TextButton(
              onPressed: isCreating ? null : onCancel,
              style: TextButton.styleFrom(
                foregroundColor: KTokens.inkMuted,
                textStyle: GoogleFonts.inter(fontSize: 14),
              ),
              child: const Text('Cancelar'),
            )
          else
            TextButton(
              onPressed: isCreating ? null : onBack,
              style: TextButton.styleFrom(
                foregroundColor: KTokens.inkMuted,
                textStyle: GoogleFonts.inter(fontSize: 14),
              ),
              child: const Text('← Atrás'),
            ),
          const Spacer(),
          ElevatedButton(
            onPressed: isCreating ? null : onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: KTokens.ink,
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(KTokens.rSm),
              ),
              textStyle: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w500),
            ),
            child: isCreating && step == totalSteps - 1
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(step < totalSteps - 1
                    ? 'Continuar →'
                    : 'Crear miembro →'),
          ),
        ],
      ),
    );
  }
}
