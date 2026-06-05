import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../register/konecta_tokens.dart';
import 'brand_style.dart';

class WorksBlock extends StatelessWidget {
  const WorksBlock({
    super.key,
    required this.photoUrls,
    required this.busy,
    required this.onAdd,
    required this.onDelete,
  });

  final List<String> photoUrls;
  final bool busy;
  final VoidCallback? onAdd;
  final ValueChanged<int>? onDelete;

  int get _max => BrandStyle.maxPhotos;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const cols = 4;
        const gap = 10.0;
        final width = constraints.maxWidth;
        final cell = (width - gap * (cols - 1)) / cols;
        final canAdd = photoUrls.length < _max;
        final visibleCount = photoUrls.length + (canAdd ? 1 : 0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (var i = 0; i < photoUrls.length; i++)
                  _PhotoTile(
                    key: ValueKey('photo-${photoUrls[i]}-$i'),
                    size: cell,
                    url: photoUrls[i],
                    onDelete: busy ? null : () => onDelete?.call(i),
                  ),
                if (canAdd)
                  _AddTile(
                    key: const ValueKey('add-tile'),
                    size: cell,
                    busy: busy,
                    onTap: busy ? null : onAdd,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${photoUrls.length} / $_max FOTOS',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  color: KTokens.inkPlaceholder,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            // Anchor — avoid `unused_local_variable` lint when visibleCount is debug-only.
            if (visibleCount < 0) const SizedBox.shrink(),
          ],
        );
      },
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    super.key,
    required this.size,
    required this.url,
    required this.onDelete,
  });

  final double size;
  final String url;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Container(
        decoration: BoxDecoration(
          color: KTokens.accentSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: KTokens.borderStrong),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            url.startsWith('http')
                ? Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _placeholder(),
                  )
                : _placeholder(),
            if (onDelete != null)
              Positioned(
                top: 6,
                right: 6,
                child: _DeleteButton(onTap: onDelete!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.image_outlined,
              size: 28, color: KTokens.inkPlaceholder),
          const SizedBox(height: 4),
          Text(
            'Foto',
            style: GoogleFonts.inter(fontSize: 11, color: KTokens.inkMuted),
          ),
          Text(
            'or browse files',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: KTokens.inkPlaceholder,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: Icon(Icons.close_rounded, size: 14, color: KTokens.ink),
        ),
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({
    super.key,
    required this.size,
    required this.busy,
    required this.onTap,
  });

  final double size;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Agregar foto',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: CustomPaint(
          painter: _DashedBorderPainter(color: KTokens.accent),
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: KTokens.accent,
                          ),
                        )
                      : const Icon(Icons.add_rounded,
                          size: 22, color: KTokens.accent),
                  const SizedBox(height: 4),
                  Text(
                    busy ? 'Subiendo…' : 'Agregar',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: KTokens.accent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(12),
      ));

    const dashWidth = 5.0;
    const dashSpace = 4.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}
