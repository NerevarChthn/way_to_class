import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:way_to_class/service/map_service.dart';

class GeminiService {
  static Future<void> testGemini() async {
    final model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: dotenv.env['API_KEY'] ?? 'API Key not found',
    );

    final Uint8List imageBytes = await MapService.loadAssetImage(
      'assets/old/map1.png',
    );

    final prompt = Content.multi([
      TextPart('beschreibe mir kurz wie ich zu Raum B027 komme'),
      DataPart('image/png', imageBytes),
    ]);

    try {
      final response = await model.generateContent([prompt]);
      print(response.text);
    } on ServerException catch (e) {
      print('ServerException: ${e.message}');
    }
  }
}
