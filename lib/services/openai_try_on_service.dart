import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/clothing_item.dart';
import '../models/user_profile.dart';

class OpenAiTryOnService {
  static const String _endpoint = 'https://api.openai.com/v1/responses';

  Future<Uint8List> generateTryOn({
    required String apiKey,
    required String model,
    required Uint8List personPhotoBytes,
    required String personPhotoMimeType,
    required Uint8List clothingPhotoBytes,
    required String clothingPhotoMimeType,
    required ClothingSize clothingSize,
    required String clothingName,
    required int heightCm,
    required int weightKg,
    required UserGender gender,
    required int ageYears,
  }) async {
    if (apiKey.trim().isEmpty) {
      throw const TryOnException(
        'Не найден OPENAI_API_KEY. Передайте ключ через --dart-define.',
      );
    }
    if (model.toLowerCase().startsWith('dall-e')) {
      throw const TryOnException(
        'Модель dall-e не подходит для этой примерки. Используйте OPENAI_MODEL=gpt-4.1.',
      );
    }
    if (personPhotoBytes.isEmpty || clothingPhotoBytes.isEmpty) {
      throw const TryOnException(
        'Не удалось прочитать изображения для примерки',
      );
    }

    final prompt = _buildPrompt(
      clothingName: clothingName,
      clothingSize: clothingSize,
      heightCm: heightCm,
      weightKg: weightKg,
      gender: gender,
      ageYears: ageYears,
    );

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: <String, String>{
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'model': model,
        'tools': <Map<String, String>>[
          <String, String>{'type': 'image_generation'},
        ],
        'input': <Map<String, dynamic>>[
          <String, dynamic>{
            'role': 'user',
            'content': <Map<String, String>>[
              <String, String>{'type': 'input_text', 'text': prompt},
              <String, String>{
                'type': 'input_image',
                'image_url':
                    'data:${_normalizeMimeType(personPhotoMimeType)};base64,${base64Encode(personPhotoBytes)}',
              },
              <String, String>{
                'type': 'input_image',
                'image_url':
                    'data:${_normalizeMimeType(clothingPhotoMimeType)};base64,${base64Encode(clothingPhotoBytes)}',
              },
            ],
          },
        ],
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw TryOnException(
        _extractApiError(response.body) ??
            'Ошибка OpenAI API (${response.statusCode})',
      );
    }

    return _extractResultImage(response.body);
  }

  Uint8List _extractResultImage(String body) {
    final dynamic decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const TryOnException('Неверный формат ответа от AI сервиса');
    }

    final dynamic output = decoded['output'];
    if (output is! List || output.isEmpty) {
      throw const TryOnException('AI сервис вернул пустой результат');
    }

    for (final dynamic item in output) {
      if (item is! Map<String, dynamic>) continue;

      if (item['type'] == 'image_generation_call') {
        final generated = _tryDecodeBase64(item['result'] as String?);
        if (generated != null) {
          return generated;
        }
      }

      final dynamic content = item['content'];
      if (content is! List) continue;

      for (final dynamic part in content) {
        if (part is! Map<String, dynamic>) continue;

        final generatedFromImageBase64 = _tryDecodeBase64(
          part['image_base64'] as String?,
        );
        if (generatedFromImageBase64 != null) {
          return generatedFromImageBase64;
        }

        final generatedFromResult = _tryDecodeBase64(part['result'] as String?);
        if (generatedFromResult != null) {
          return generatedFromResult;
        }
      }
    }

    throw TryOnException(
      _extractOutputText(output) ?? 'AI сервис не вернул изображение',
    );
  }

  Uint8List? _tryDecodeBase64(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      final bytes = base64Decode(value);
      if (bytes.isEmpty) return null;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  String _buildPrompt({
    required String clothingName,
    required ClothingSize clothingSize,
    required int heightCm,
    required int weightKg,
    required UserGender gender,
    required int ageYears,
  }) {
    return '''
Use the first image as the person's photo and the second image as the clothing reference.
Create a realistic virtual try-on where the person is wearing the referenced clothing.
Preserve face identity, body proportions, skin tone and background from the first image.
Do not add extra accessories or extra garments.
User profile:
- gender: ${gender.name}
- age_years: $ageYears
- height_cm: $heightCm
- weight_kg: $weightKg
Clothing metadata:
- name: $clothingName
- size: ${clothingSize.label}
''';
  }

  String _normalizeMimeType(String mimeType) {
    if (mimeType.trim().isEmpty) return 'image/jpeg';
    return mimeType.trim();
  }

  String? _extractOutputText(List<dynamic> output) {
    for (final dynamic item in output) {
      if (item is! Map<String, dynamic>) continue;
      final dynamic content = item['content'];
      if (content is! List) continue;
      for (final dynamic part in content) {
        if (part is! Map<String, dynamic>) continue;
        final String? text = part['text'] as String?;
        if (text != null && text.isNotEmpty) return text;
      }
    }
    return null;
  }

  String? _extractApiError(String body) {
    try {
      final dynamic decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final dynamic error = decoded['error'];
        if (error is Map<String, dynamic>) {
          final dynamic message = error['message'];
          if (message is String && message.isNotEmpty) {
            return message;
          }
        }
      }
    } catch (_) {
      // Fall through and return null.
    }
    return null;
  }
}

class TryOnException implements Exception {
  final String message;
  const TryOnException(this.message);

  @override
  String toString() => message;
}
