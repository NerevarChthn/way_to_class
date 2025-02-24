import 'package:flutter/services.dart';

class MapService {
  static Future<Uint8List> loadAssetImage(String path) async {
    return await rootBundle
        .load(path)
        .then((byteData) => byteData.buffer.asUint8List());
  }
}
