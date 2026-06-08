import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/agenda_media_image.dart';
import '../../../../providers/agenda/tenant/business_photos_provider.dart';
import '../../../../widgets/agenda/agenda_state_views.dart';
import '../utils/business_work_photo_upload.dart';

class PhotosTab extends ConsumerWidget {
  const PhotosTab({
    super.key,
    required this.tenantId,
    required this.businessId,
  });

  final String tenantId;
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (tenantId: tenantId, businessId: businessId);
    final state = ref.watch(businessPhotosProvider(key));

    if (state.isLoading) return const AgendaLoadingView(message: 'Cargando fotos…');
    if (state.error != null) {
      return AgendaErrorView(
        message: state.error!,
        onRetry: () => ref.read(businessPhotosProvider(key).notifier).load(),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fotos de trabajos',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${state.photos.length}/10 fotos',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              if (state.photos.length < 10)
                FilledButton.icon(
                  icon: state.isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.add_photo_alternate_outlined, size: 18),
                  label: const Text('Subir foto'),
                  onPressed: state.isSaving
                      ? null
                      : () => pickAndUploadBusinessWorkPhoto(
                            context: context,
                            ref: ref,
                            key: key,
                          ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (state.photos.isEmpty)
            const Expanded(
              child: AgendaEmptyState(
                icon: Icons.photo_library_outlined,
                title: 'Sin fotos todavía',
                subtitle: 'Subí hasta 10 fotos de tus trabajos (PNG, JPG o WEBP — máx. 5 MB)',
              ),
            )
          else
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: state.photos.length,
                itemBuilder: (ctx, i) {
                  final photo = state.photos[i];
                  return _PhotoCard(
                    url: photo.url,
                    onDelete: state.isSaving
                        ? null
                        : () => _confirmDelete(context, ref, key, photo.id),
                  );
                },
              ),
            ),
          if (state.error != null) ...[
            const SizedBox(height: 8),
            Text(state.error!,
                style: TextStyle(color: Colors.red.shade600, fontSize: 13)),
          ],
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref,
      ({String tenantId, String businessId}) key, String photoId) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar foto'),
        content: const Text('¿Estás seguro de que querés eliminar esta foto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(businessPhotosProvider(key).notifier).deletePhoto(photoId);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({required this.url, required this.onDelete});

  final String url;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AgendaMediaImage(
            url: url,
            fit: BoxFit.cover,
            expand: true,
            errorWidget: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.broken_image_outlined,
                    size: 40, color: Colors.grey),
              ),
            ),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }
}
