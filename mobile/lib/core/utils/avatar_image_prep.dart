import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Réduit et convertit la photo (HEIC, etc.) en JPEG léger pour l'upload.
Future<Uint8List> prepareAvatarImage(String filePath) async {
  if (!kIsWeb) {
    final compressed = await FlutterImageCompress.compressWithFile(
      filePath,
      minWidth: 512,
      minHeight: 512,
      quality: 78,
      format: CompressFormat.jpeg,
    );
    if (compressed != null && compressed.isNotEmpty) {
      return compressed;
    }
  }

  throw Exception('Impossible de préparer la photo de profil');
}
