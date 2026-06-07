import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../features/agenda/register/konecta_tokens.dart';
import '../../../providers/agenda/public/public_categories_provider.dart';

class EditCategoriesModal extends ConsumerStatefulWidget {
  const EditCategoriesModal({super.key, required this.selectedSlugs});

  final List<String> selectedSlugs;

  static Future<List<String>?> show(
    BuildContext context,
    List<String> selectedSlugs,
  ) =>
      showDialog<List<String>>(
        context: context,
        builder: (_) => EditCategoriesModal(selectedSlugs: selectedSlugs),
      );

  @override
  ConsumerState<EditCategoriesModal> createState() =>
      _EditCategoriesModalState();
}

class _EditCategoriesModalState extends ConsumerState<EditCategoriesModal> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedSlugs.toSet();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(publicCategoriesProvider);

    return Dialog(
      backgroundColor: KTokens.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 460,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Categorías',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: KTokens.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Seleccioná los rubros que representan tu negocio.',
                style: GoogleFonts.inter(fontSize: 12.5, color: KTokens.inkSoft),
              ),
              const SizedBox(height: 16),
              categoriesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (err, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No se pudieron cargar las categorías.',
                    style: GoogleFonts.inter(fontSize: 13, color: KTokens.inkMuted),
                  ),
                ),
                data: (categories) => ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: categories.length,
                    itemBuilder: (_, i) {
                      final cat = categories[i];
                      final isSel = _selected.contains(cat.slug) ||
                          _selected.contains(cat.id);
                      return InkWell(
                        onTap: () => setState(() {
                          if (isSel) {
                            _selected.remove(cat.slug);
                            _selected.remove(cat.id);
                          } else {
                            _selected.add(cat.slug);
                          }
                        }),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 4),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 120),
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? KTokens.accent
                                      : KTokens.surface,
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color: isSel
                                        ? KTokens.accent
                                        : KTokens.borderStrong,
                                  ),
                                ),
                                child: isSel
                                    ? const Icon(Icons.check,
                                        size: 12, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                cat.nombre,
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  color: KTokens.ink,
                                  fontWeight: isSel
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _Btn(
                    label: 'Cancelar',
                    filled: false,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 10),
                  _Btn(
                    label: 'Guardar',
                    filled: true,
                    onTap: () =>
                        Navigator.of(context).pop(_selected.toList()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn({
    required this.label,
    required this.filled,
    required this.onTap,
  });
  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: filled ? KTokens.ink : KTokens.surface,
            borderRadius: BorderRadius.circular(KTokens.rPill),
            border: filled ? null : Border.all(color: KTokens.borderStrong),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: filled ? Colors.white : KTokens.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
