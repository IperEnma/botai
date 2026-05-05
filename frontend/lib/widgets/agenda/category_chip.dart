import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../features/agenda/theme/agenda_tokens.dart';
import '../../models/agenda/category.dart';

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.category,
    this.selected = false,
    this.onTap,
  });

  final Category category;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? AppTheme.primaryColor.withValues(alpha: 0.12)
        : Colors.grey.shade100;
    final fg = selected ? AppTheme.primaryColor : Colors.grey.shade800;
    final border = selected ? AppTheme.primaryColor : Colors.grey.shade300;

    return InkWell(
      borderRadius: BorderRadius.circular(AgendaTokens.chipRadius),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AgendaTokens.chipRadius),
          border: Border.all(color: border),
        ),
        child: Text(
          category.nombre,
          style: TextStyle(
            color: fg,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
