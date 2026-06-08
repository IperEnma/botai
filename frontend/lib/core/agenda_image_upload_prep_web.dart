// Web: redimensiona/comprime antes de POST multipart (Render ~30s, Neon BYTEA).
// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:typed_data';

class PreparedImageUpload {
  const PreparedImageUpload({required this.bytes, required this.fileName});

  final Uint8List bytes;
  final String fileName;
}

/// Portada: ancho máximo 1920px, JPEG ~82 % (suele bajar de MB a ~200–400 KB).
Future<PreparedImageUpload> prepareBannerUpload(html.File file) {
  return _prepareImageUpload(
    file,
    maxWidth: 1920,
    maxHeight: 1080,
    quality: 0.82,
    namePrefix: 'banner',
  );
}

/// Logo: cuadrado max 512px.
Future<PreparedImageUpload> prepareLogoUpload(html.File file) {
  return _prepareImageUpload(
    file,
    maxWidth: 512,
    maxHeight: 512,
    quality: 0.88,
    namePrefix: 'logo',
  );
}

/// Foto de trabajo: cuadrado max 1200px.
Future<PreparedImageUpload> prepareWorkPhotoUpload(html.File file) {
  return _prepareImageUpload(
    file,
    maxWidth: 1200,
    maxHeight: 1200,
    quality: 0.85,
    namePrefix: 'work',
  );
}

/// Abre el selector de archivos y devuelve la imagen preparada, o null si cancela.
Future<PreparedImageUpload?> pickWorkPhotoUpload() async {
  final input = html.FileUploadInputElement()..accept = 'image/*';
  final completer = Completer<PreparedImageUpload?>();

  input.onChange.listen((_) async {
    try {
      final file = input.files?.first;
      if (file == null) {
        if (!completer.isCompleted) completer.complete(null);
        return;
      }
      if (file.size > 5 * 1024 * 1024) {
        if (!completer.isCompleted) {
          completer.completeError(StateError('Máx. 5 MB.'));
        }
        return;
      }
      final prepared = await prepareWorkPhotoUpload(file);
      if (!completer.isCompleted) completer.complete(prepared);
    } catch (e, st) {
      if (!completer.isCompleted) completer.completeError(e, st);
    }
  });

  input.click();
  return completer.future;
}

Future<PreparedImageUpload> _prepareImageUpload(
  html.File file, {
  required int maxWidth,
  required int maxHeight,
  required double quality,
  required String namePrefix,
}) async {
  final ext = _extension(file.name);
  if (file.size <= 350 * 1024 && (ext == 'jpg' || ext == 'jpeg' || ext == 'webp')) {
    return PreparedImageUpload(
      bytes: await _readFileBytes(file),
      fileName: file.name,
    );
  }

  final bytes = await _compressWithCanvas(
    file,
    maxWidth: maxWidth,
    maxHeight: maxHeight,
    quality: quality,
  );
  return PreparedImageUpload(
    bytes: bytes,
    fileName: '$namePrefix-${DateTime.now().millisecondsSinceEpoch}.jpg',
  );
}

Future<Uint8List> _readFileBytes(html.File file) async {
  final reader = html.FileReader();
  reader.readAsArrayBuffer(file);
  await reader.onLoad.first;
  final result = reader.result;
  if (result == null) {
    throw StateError('No se pudo leer el archivo');
  }
  if (result is Uint8List) {
    return result;
  }
  if (result is ByteBuffer) {
    return Uint8List.view(result);
  }
  if (result is List<int>) {
    return Uint8List.fromList(result);
  }
  // Web: a veces devuelve un typed array distinto de ByteBuffer.
  return Uint8List.fromList(List<int>.from(result as Iterable<int>));
}

Future<Uint8List> _compressWithCanvas(
  html.File file, {
  required int maxWidth,
  required int maxHeight,
  required double quality,
}) async {
  final objectUrl = html.Url.createObjectUrlFromBlob(file);
  try {
    final img = html.ImageElement();
    final loaded = img.onLoad.first;
    img.src = objectUrl;
    await loaded;

    var w = img.naturalWidth;
    var h = img.naturalHeight;
    if (w <= 0 || h <= 0) {
      return _readFileBytes(file);
    }

    final scale = math.min(1.0, math.min(maxWidth / w, maxHeight / h));
    w = (w * scale).round().clamp(1, maxWidth);
    h = (h * scale).round().clamp(1, maxHeight);

    final canvas = html.CanvasElement(width: w, height: h);
    canvas.context2D.drawImageScaled(img, 0, 0, w, h);

    final blob = await canvas.toBlob('image/jpeg', quality);
    return _readFileBytes(html.File([blob], 'upload.jpg', {'type': 'image/jpeg'}));
  } finally {
    html.Url.revokeObjectUrl(objectUrl);
  }
}

String _extension(String name) {
  final i = name.lastIndexOf('.');
  if (i < 0) return '';
  return name.substring(i + 1).toLowerCase();
}
