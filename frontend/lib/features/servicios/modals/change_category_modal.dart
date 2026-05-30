import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../providers/agenda/tenant/businesses_provider.dart';
import '../../agenda/register/konecta_tokens.dart';
import '../controllers/servicios_controller.dart';
import '../models/business_category.dart';

void showChangeCategoryModal(BuildContext context, ServiciosKey key) {
  showDialog(
    context: context,
    barrierColor: const Color(0x520F0F10),
    builder: (_) => _ChangeCategoryModal(servKey: key),
  );
}

class _ChangeCategoryModal extends ConsumerStatefulWidget {
  const _ChangeCategoryModal({required this.servKey});

  final ServiciosKey servKey;

  @override
  ConsumerState<_ChangeCategoryModal> createState() =>
      _ChangeCategoryModalState();
}

class _ChangeCategoryModalState extends ConsumerState<_ChangeCategoryModal> {
  BusinessCategory? _target;

  void _confirm() {
    if (_target == null) return;
    ref.read(serviciosProvider(widget.servKey).notifier).changeCategory(_target!);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Categoría cambiada a ${_target!.displayName}',
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
        ),
        backgroundColor: KTokens.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KTokens.rSm),
        ),
      ),
    );
  }

  static String _sinceLabel(DateTime? dt) {
    if (dt == null) return '';
    const months = [
      'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
      'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC',
    ];
    return 'DESDE ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(serviciosProvider(widget.servKey));
    final businessesState =
        ref.watch(businessesProvider(widget.servKey.tenantId));
    final business = businessesState.items
        .where((b) => b.id == widget.servKey.businessId)
        .firstOrNull;
    final sinceLabel = _sinceLabel(business?.createdAt);
    final current = state.category;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 580,
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _ModalHeader(
              current: current,
              onClose: () => Navigator.of(context).pop(),
            ),
            const Divider(height: 1, color: KTokens.border),

            // Scrollable body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current category row
                    Row(
                      children: [
                        Text(
                          'CATEGORÍA ACTUAL',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            letterSpacing: 1.2,
                            color: KTokens.inkSoft,
                          ),
                        ),
                        const SizedBox(width: 10),
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
                          current.displayName,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: KTokens.accent,
                          ),
                        ),
                        const Spacer(),
                        if (sinceLabel.isNotEmpty)
                          Text(
                            sinceLabel,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              color: KTokens.inkSoft,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: KTokens.border, height: 1),
                    const SizedBox(height: 16),

                    Text(
                      'ELEGÍ UNA NUEVA',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        letterSpacing: 1.4,
                        color: KTokens.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Category grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 3.2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      children: BusinessCategory.values.map((cat) {
                        final isCurrent = cat == current;
                        final isSelected = _target == cat;
                        return GestureDetector(
                          onTap: isCurrent
                              ? null
                              : () => setState(() => _target = cat),
                          child: Opacity(
                            opacity: isCurrent ? 0.5 : 1.0,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0x143B2F63)
                                    : KTokens.surface,
                                border: Border.all(
                                  color: isSelected
                                      ? KTokens.accent
                                      : KTokens.border,
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                                borderRadius: BorderRadius.circular(KTokens.rSm),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          cat.displayName +
                                              (isCurrent ? ' · ACTUAL' : ''),
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: isSelected
                                                ? KTokens.accent
                                                : KTokens.ink,
                                          ),
                                        ),
                                        Text(
                                          cat.typicalServices,
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 9,
                                            letterSpacing: 0.8,
                                            color: KTokens.inkSoft,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    // Warning (visible when target selected and != current)
                    if (_target != null && _target != current) ...[
                      const SizedBox(height: 20),
                      _WarningBox(targetName: _target!.displayName),
                    ],
                  ],
                ),
              ),
            ),

            // Footer
            const Divider(height: 1, color: KTokens.border),
            _ModalFooter(
              target: _target,
              current: current,
              onCancel: () => Navigator.of(context).pop(),
              onConfirm: _target != null && _target != current ? _confirm : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Modal header ─────────────────────────────────────────────────────────────

class _ModalHeader extends StatelessWidget {
  const _ModalHeader({
    required this.current,
    required this.onClose,
  });

  final BusinessCategory current;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONFIGURACIÓN DEL NEGOCIO',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    letterSpacing: 1.4,
                    color: KTokens.inkSoft,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cambiar categoría',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: KTokens.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'La categoría define las sugerencias disponibles.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: KTokens.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            color: KTokens.inkMuted,
            onPressed: onClose,
            splashRadius: 16,
          ),
        ],
      ),
    );
  }
}

// ─── Warning box ──────────────────────────────────────────────────────────────

class _WarningBox extends StatelessWidget {
  const _WarningBox({required this.targetName});

  final String targetName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: KTokens.warnBg,
        border: Border.all(color: KTokens.warnBorder),
        borderRadius: BorderRadius.circular(KTokens.rSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_rounded, size: 16, color: KTokens.warn),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cambiar a $targetName afecta tu catálogo actual',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: KTokens.warn,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _WarnLine(
            'LAS SUGERENCIAS DE LA CATEGORÍA ACTUAL SE REEMPLAZAN POR LAS DE $targetName'.toUpperCase(),
          ),
          _WarnLine('TURNOS Y PROFESIONALES NO CAMBIAN'),
        ],
      ),
    );
  }
}

class _WarnLine extends StatelessWidget {
  const _WarnLine(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '· ',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              color: KTokens.warn,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                color: KTokens.warn,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Modal footer ─────────────────────────────────────────────────────────────

class _ModalFooter extends StatelessWidget {
  const _ModalFooter({
    required this.target,
    required this.current,
    required this.onCancel,
    required this.onConfirm,
  });

  final BusinessCategory? target;
  final BusinessCategory current;
  final VoidCallback onCancel;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final label = target != null && target != current
        ? 'Cambiar a ${target!.displayName} →'
        : 'Seleccioná una categoría';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: KTokens.ink,
              side: const BorderSide(color: KTokens.border),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(KTokens.rSm),
              ),
              textStyle: GoogleFonts.inter(fontSize: 13),
            ),
            child: const Text('Cancelar'),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: KTokens.ink,
              foregroundColor: Colors.white,
              disabledBackgroundColor: KTokens.border,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(KTokens.rSm),
              ),
              textStyle:
                  GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            child: Text(label),
          ),
        ],
      ),
    );
  }
}
