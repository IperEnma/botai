import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/agenda/agenda_service.dart';
import '../../../../providers/agenda/tenant/business_staff_provider.dart';
import '../../../../providers/agenda/tenant/services_provider.dart';
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
      pageBuilder: (_, _, _) => _AddMemberPanel(equipoKey: key),
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

class _AddMemberPanel extends ConsumerStatefulWidget {
  const _AddMemberPanel({required this.equipoKey});

  final EquipoKey equipoKey;

  @override
  ConsumerState<_AddMemberPanel> createState() => _AddMemberPanelState();
}

class _AddMemberPanelState extends ConsumerState<_AddMemberPanel> {
  int _step = 0; // 0, 1, 2
  bool _isCreating = false;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  MemberType _selectedType = MemberType.profesionalConCuenta;
  Color _selectedColor = KTokens.proPalette[0];
  final Set<String> _selectedServices = {};

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < 2) {
      setState(() => _step++);
    } else {
      _create();
    }
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    final rol = switch (_selectedType) {
      MemberType.recepcion => 'Recepcionista',
      MemberType.profesionalSoloPerfil => 'Profesional',
      MemberType.profesionalConCuenta => 'Profesional',
    };

    setState(() => _isCreating = true);

    final staffKey = (
      tenantId: widget.equipoKey.tenantId,
      businessId: widget.equipoKey.businessId,
    );
    final notifier = ref.read(businessStaffProvider(staffKey).notifier);

    final phone = _phoneCtrl.text.trim();
    final colorHex = '#${(_selectedColor.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
    final result = await notifier.addMember(name, rol, null, telefono: phone.isEmpty ? null : phone, color: colorHex);

    if (!mounted) return;

    if (result != null) {
      if (_selectedServices.isNotEmpty) {
        await notifier.updateMemberServices(result.id, _selectedServices.toList());
      }
      Navigator.of(context).pop();
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
    final servicesState = ref.watch(
      servicesProvider((
        tenantId: widget.equipoKey.tenantId,
        businessId: widget.equipoKey.businessId,
      )),
    );
    final services = servicesState.items.where((s) => s.activo).toList();

    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 480,
        child: Material(
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
                        _ProgressBar(step: _step),
                        const SizedBox(height: 8),
                        Text(
                          'PASO 0${_step + 1} DE 03',
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
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 26,
                            fontStyle: FontStyle.italic,
                            color: KTokens.ink,
                            height: 1.2,
                          ),
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
                          selectedType: _selectedType,
                          selectedColor: _selectedColor,
                          selectedServices: _selectedServices,
                          services: services,
                          onTypeChanged: (t) =>
                              setState(() => _selectedType = t),
                          onColorChanged: (c) =>
                              setState(() => _selectedColor = c),
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
                  isCreating: _isCreating,
                  onBack: _back,
                  onNext: _next,
                ),
              ],
            ),
          ),
        ),
      ),
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
  const _ProgressBar({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        final isDone = i < step;
        final isCurrent = i == step;
        return Expanded(
          child: Container(
            height: 3,
            margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
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
    required this.selectedType,
    required this.selectedColor,
    required this.selectedServices,
    required this.services,
    required this.onTypeChanged,
    required this.onColorChanged,
    required this.onServiceToggled,
  });

  final int step;
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final MemberType selectedType;
  final Color selectedColor;
  final Set<String> selectedServices;
  final List<AgendaService> services;
  final ValueChanged<MemberType> onTypeChanged;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<String> onServiceToggled;

  @override
  Widget build(BuildContext context) {
    return switch (step) {
      0 => _Step1(nameCtrl: nameCtrl, phoneCtrl: phoneCtrl),
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

// Step 1: Name + phone
class _Step1 extends StatelessWidget {
  const _Step1({required this.nameCtrl, required this.phoneCtrl});
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _LineInput(controller: nameCtrl, hint: 'NOMBRE COMPLETO'),
        const SizedBox(height: 24),
        _LineInput(controller: phoneCtrl, hint: 'WHATSAPP'),
      ],
    );
  }
}

class _LineInput extends StatelessWidget {
  const _LineInput({required this.controller, required this.hint});
  final TextEditingController controller;
  final String hint;

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
            contentPadding:
                EdgeInsets.symmetric(vertical: 8),
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
    final types = [
      (
        MemberType.profesionalConCuenta,
        'Profesional con cuenta',
        'Puede iniciar sesión y gestionar su agenda. RECOMENDADO',
        true,
      ),
      (
        MemberType.profesionalSoloPerfil,
        'Profesional solo perfil',
        'Aparece en la agenda pero no puede iniciar sesión.',
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
        final (type, name, desc, recommended) = t;
        final isActive = selected == type;
        return GestureDetector(
          onTap: () => onChanged(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                              color:
                                  isActive ? KTokens.accent : KTokens.ink,
                            ),
                          ),
                          if (recommended) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: KTokens.accent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'RECOMENDADO',
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
                          color: isActive ? KTokens.accent : KTokens.inkMuted,
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
        // Color
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

        // Services
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? KTokens.accentSoft
                        : const Color(0x0C000000),
                    border: Border.all(
                      color:
                          isSelected ? KTokens.accent : Colors.transparent,
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: KTokens.accentSoft,
              border: Border.all(color: KTokens.accent.withValues(alpha: 0.3)),
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
    required this.isCreating,
    required this.onBack,
    required this.onNext,
  });

  final int step;
  final bool isCreating;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: KTokens.border)),
      ),
      child: Row(
        children: [
          if (step > 0)
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
            child: isCreating && step == 2
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(step < 2 ? 'Continuar →' : 'Crear miembro →'),
          ),
        ],
      ),
    );
  }
}
