import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../providers/agenda/tenant/businesses_provider.dart';
import '../../agenda/register/konecta_tokens.dart';
import '../../agenda/shared/k_button.dart';
import '../controllers/servicios_controller.dart';
import '../models/business_category.dart';

const int _kMaxCategories = 3;

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
  late List<BusinessCategory> _selected;
  late List<BusinessCategory> _initial;

  @override
  void initState() {
    super.initState();
    final cats =
        ref.read(serviciosProvider(widget.servKey)).categories;
    _initial = List<BusinessCategory>.from(cats);
    _selected = List<BusinessCategory>.from(cats);
  }

  bool get _isDirty {
    if (_selected.length != _initial.length) return true;
    final initSet = _initial.toSet();
    for (final c in _selected) {
      if (!initSet.contains(c)) return true;
    }
    return false;
  }

  bool get _atLimit => _selected.length >= _kMaxCategories;
  bool get _hasOtra => _selected.contains(BusinessCategory.otra);
  bool get _hasNonOtra =>
      _selected.any((c) => c != BusinessCategory.otra);

  bool _isBlocked(BusinessCategory cat) {
    if (_selected.contains(cat)) return false;
    if (_atLimit) return true;
    final isOtra = cat == BusinessCategory.otra;
    if (isOtra && _hasNonOtra) return true;
    if (!isOtra && _hasOtra) return true;
    return false;
  }

  void _toggle(BusinessCategory cat) {
    setState(() {
      if (_selected.contains(cat)) {
        _selected.remove(cat);
      } else if (!_isBlocked(cat)) {
        _selected.add(cat);
      }
    });
  }

  bool _saving = false;

  Future<void> _confirm() async {
    if (_selected.isEmpty || !_isDirty || _saving) return;
    setState(() => _saving = true);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final snapshot = List<BusinessCategory>.from(_selected);

    try {
      await ref
          .read(serviciosProvider(widget.servKey).notifier)
          .setCategories(snapshot);
    } finally {
      if (mounted) setState(() => _saving = false);
    }

    if (!mounted) return;
    navigator.pop();
    final label = snapshot.length == 1
        ? snapshot.first.displayName
        : '${snapshot.length} categorías';
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Categorías actualizadas: $label',
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
    final businessesState =
        ref.watch(businessesProvider(widget.servKey.tenantId));
    final business = businessesState.items
        .where((b) => b.id == widget.servKey.businessId)
        .firstOrNull;
    final sinceLabel = _sinceLabel(business?.createdAt);

    final isNarrow = MediaQuery.sizeOf(context).width < 600;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 16 : 40,
        vertical: 40,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 580,
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ModalHeader(
              isMulti: _initial.length > 1,
              onClose: () => Navigator.of(context).pop(),
            ),
            const Divider(height: 1, color: KTokens.border),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current categories row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          _initial.length > 1
                              ? 'CATEGORÍAS ACTUALES'
                              : 'CATEGORÍA ACTUAL',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            letterSpacing: 1.2,
                            color: KTokens.inkSoft,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              for (final c in _initial)
                                Row(
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
                                      c.displayName,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: KTokens.accent,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
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

                    // Section header with counter
                    Row(
                      children: [
                        Text(
                          'ELEGÍ HASTA $_kMaxCategories',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            letterSpacing: 1.4,
                            color: KTokens.inkSoft,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_selected.length}/$_kMaxCategories',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            letterSpacing: 1.0,
                            color: _atLimit
                                ? KTokens.accent
                                : KTokens.inkSoft,
                            fontWeight: _atLimit
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Category grid (multi-select)
                    GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisExtent: 80,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      children: BusinessCategory.values.map((cat) {
                        final isSelected = _selected.contains(cat);
                        final isInitial = _initial.contains(cat);
                        final disabled = _isBlocked(cat);
                        return GestureDetector(
                          onTap: disabled ? null : () => _toggle(cat),
                          child: Opacity(
                            opacity: disabled ? 0.4 : 1.0,
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
                                borderRadius:
                                    BorderRadius.circular(KTokens.rSm),
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
                                              (isInitial ? ' · ACTUAL' : ''),
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
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: KTokens.accent,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    if (_atLimit) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Llegaste al máximo. Desmarcá una para elegir otra.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: KTokens.inkMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ] else if (_hasOtra) ...[
                      const SizedBox(height: 12),
                      Text(
                        '"Otra" no se combina con otras categorías. Desmarcala para elegir alguna específica.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: KTokens.inkMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ] else if (_hasNonOtra) ...[
                      const SizedBox(height: 12),
                      Text(
                        '"Otra" no se combina con categorías específicas.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: KTokens.inkMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],

                    if (_isDirty && _selected.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const _WarningBox(),
                    ],
                  ],
                ),
              ),
            ),

            const Divider(height: 1, color: KTokens.border),
            _ModalFooter(
              selectedCount: _selected.length,
              isDirty: _isDirty,
              saving: _saving,
              onCancel: _saving ? null : () => Navigator.of(context).pop(),
              onConfirm: _selected.isNotEmpty && _isDirty && !_saving
                  ? _confirm
                  : null,
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
    required this.isMulti,
    required this.onClose,
  });

  final bool isMulti;
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
                  isMulti ? 'Cambiar categorías' : 'Cambiar categoría',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: KTokens.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Elegí hasta $_kMaxCategories. Definen las sugerencias disponibles.',
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
  const _WarningBox();

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
                  'Cambio en categorías afecta tu catálogo de sugerencias',
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
          const _WarnLine(
            'LAS SUGERENCIAS SE AJUSTAN A LAS CATEGORÍAS SELECCIONADAS',
          ),
          const _WarnLine('TURNOS Y PROFESIONALES NO CAMBIAN'),
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
    required this.selectedCount,
    required this.isDirty,
    required this.saving,
    required this.onCancel,
    required this.onConfirm,
  });

  final int selectedCount;
  final bool isDirty;
  final bool saving;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final label = selectedCount == 0
        ? 'Seleccioná al menos una'
        : (!isDirty
            ? 'Sin cambios'
            : (selectedCount == 1
                ? 'Guardar 1 categoría'
                : 'Guardar $selectedCount categorías'));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          KButton.secondary(
            label: 'Cancelar',
            onPressed: onCancel,
          ),
          const Spacer(),
          KButton.primary(
            label: label,
            trailing: (selectedCount > 0 && isDirty)
                ? Icons.arrow_forward_rounded
                : null,
            loading: saving,
            onPressed: onConfirm,
          ),
        ],
      ),
    );
  }
}
