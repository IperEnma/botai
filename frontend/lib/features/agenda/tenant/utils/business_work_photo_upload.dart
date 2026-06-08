import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/agenda_image_upload_prep_web.dart';
import '../../../../providers/agenda/public/public_business_slug_provider.dart';
import '../../../../providers/agenda/tenant/business_photos_provider.dart';

typedef BusinessPhotoKey = ({String tenantId, String businessId});

/// Selector de archivo + upload multipart (mismo flujo que logo/portada).
Future<bool> pickAndUploadBusinessWorkPhoto({
  required BuildContext context,
  required WidgetRef ref,
  required BusinessPhotoKey key,
  String? publicSlug,
}) async {
  try {
    final prepared = await pickWorkPhotoUpload();
    if (prepared == null) return false;

    final ok = await ref.read(businessPhotosProvider(key).notifier).uploadPhoto(
          bytes: prepared.bytes,
          fileName: prepared.fileName,
        );

    if (!context.mounted) return ok;

    if (ok) {
      if (publicSlug != null && publicSlug.isNotEmpty) {
        ref.invalidate(publicPhotosBySlugProvider(publicSlug));
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto agregada')),
      );
      return true;
    }

    final err = ref.read(businessPhotosProvider(key)).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(err ?? 'Error al subir la foto'),
        backgroundColor: Colors.red.shade700,
      ),
    );
    return false;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
    return false;
  }
}
