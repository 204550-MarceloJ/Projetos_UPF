import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Redimensiona e comprime uma imagem para caber no CSV
Future<String> resizeAndConvertToBase64(Uint8List originalBytes,
    {int maxWidth = 200, int quality = 70}) async {
  try {
    final image = img.decodeImage(originalBytes);
    if (image == null) return "";

    final resized = img.copyResize(image, width: maxWidth);

    // Converte para JPEG comprimido
    final jpg = img.encodeJpg(resized, quality: quality);

    // Retorna string base64
    return "data:image/jpeg;base64,${base64Encode(jpg)}";
  } catch (e) {
    return "";
  }
}
