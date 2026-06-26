import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

Future<Uint8List> prepareImageForSearch(XFile file) async {
  if (!kIsWeb) {
    final compressed = await FlutterImageCompress.compressWithFile(
      file.path,
      minWidth: 768,
      minHeight: 768,
      quality: 62,
      format: CompressFormat.jpeg,
    );
    if (compressed != null && compressed.isNotEmpty) {
      return compressed;
    }

    final raw = await file.readAsBytes();
    if (raw.isNotEmpty) {
      final converted = await FlutterImageCompress.compressWithList(
        raw,
        minWidth: 768,
        minHeight: 768,
        quality: 62,
        format: CompressFormat.jpeg,
      );
      if (converted != null && converted.isNotEmpty) {
        return converted;
      }
    }
  } else {
    final bytes = await file.readAsBytes();
    if (bytes.isNotEmpty) {
      return bytes;
    }
  }

  throw Exception('Image vide ou format non supporté (utilisez JPG/PNG)');
}
