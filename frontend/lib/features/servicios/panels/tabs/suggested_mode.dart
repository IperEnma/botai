import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../agenda/register/konecta_tokens.dart';
import '../../data/service_group_catalog.dart';
import '../../data/template_catalog.dart';
import '../../models/business_category.dart';
import '../../models/service_template.dart';

class SuggestedMode extends StatefulWidget {
  const SuggestedMode({
    super.key,
    required this.category,
    required this.existingIds,
    required this.onSelectionChanged,
    required this.onSwitchToCustom,
  });

  final BusinessCategory category;
  final Set<String> existingIds;
  final ValueChanged<Set<String>> onSelectionChanged;
  final VoidCallback onSwitchToCustom;

  @override
  State<SuggestedMode> createState() => _SuggestedModeState();
}

class _SuggestedModeState extends State<SuggestedMode> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final templates = TemplateCatalog.forCategory(widget.category);
    final groups = ServiceGroupCatalog.forCategory(widget.category);

    // Group templates by groupId
    final grouped = <String, List<ServiceTemplate>>{};
    for (final t in templates) {
      grouped.putIfAbsent(t.groupId, () => []).add(t);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0x0A3B2F63),
              border: Border.all(color: const Color(0x263B2F63)),
              borderRadius: BorderRadius.circular(KTokens.rSm),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4, right: 10),
                  decoration: const BoxDecoration(
                    color: KTokens.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Mostramos sugerencias típicas para ${widget.category.displayName}. '
                    'Tocá para agregarlas — podés editar precio y duración después.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: KTokens.accent,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Template groups
          ...groups.map((group) {
            final groupTemplates = grouped[group.id] ?? [];
            if (groupTemplates.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name.toUpperCase(),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: KTokens.inkSoft,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: groupTemplates.length,
                  itemBuilder: (_, i) {
                    final t = groupTemplates[i];
                    final isSelected = _selected.contains(t.id);
                    final alreadyAdded = widget.existingIds.contains(t.id);
                    return _TemplateCard(
                      template: t,
                      isSelected: isSelected,
                      alreadyAdded: alreadyAdded,
                      onTap: alreadyAdded
                          ? null
                          : () {
                              setState(() {
                                if (isSelected) {
                                  _selected.remove(t.id);
                                } else {
                                  _selected.add(t.id);
                                }
                              });
                              widget.onSelectionChanged(Set.from(_selected));
                            },
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            );
          }),

          // Fallback
          GestureDetector(
            onTap: widget.onSwitchToCustom,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: KTokens.border),
                borderRadius: BorderRadius.circular(KTokens.rSm),
              ),
              child: Text(
                '¿No está lo que buscás? Creá uno desde cero →',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: KTokens.inkMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Template card ────────────────────────────────────────────────────────────

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.isSelected,
    required this.alreadyAdded,
    required this.onTap,
  });

  final ServiceTemplate template;
  final bool isSelected;
  final bool alreadyAdded;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: alreadyAdded ? 0.5 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0x143B2F63) : KTokens.surface,
            border: Border.all(
              color: isSelected ? KTokens.accent : KTokens.border,
              width: isSelected ? 1.5 : 1.0,
            ),
            borderRadius: BorderRadius.circular(KTokens.rSm),
          ),
          child: Stack(
            children: [
              // Content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: KTokens.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Expanded(
                    child: Text(
                      template.description,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: KTokens.inkMuted,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${template.defaultDurationMinutes}M · UY \$${template.defaultPriceUyu}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9,
                      color: KTokens.inkSoft,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),

              // Corner indicator
              Positioned(
                top: 0,
                right: 0,
                child: alreadyAdded
                    ? Text(
                        'YA TENÉS',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9,
                          color: KTokens.inkPlaceholder,
                        ),
                      )
                    : Text(
                        isSelected ? '✓' : '+',
                        style: GoogleFonts.inter(
                          fontSize: isSelected ? 14 : 16,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isSelected ? KTokens.accent : KTokens.inkSoft,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Mock existing IDs helper ─────────────────────────────────────────────────

Set<String> buildExistingIds(List<String> serviceIds) => serviceIds.toSet();
