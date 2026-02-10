import 'package:ai_tryon/models/clothing_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WardrobeItem', () {
    test('serializes and deserializes correctly', () {
      final item = WardrobeItem(
        id: 'id-1',
        name: 'Пальто',
        imagePath: '/tmp/palto.jpg',
        size: ClothingSize.l,
        createdAt: DateTime.parse('2026-02-10T10:00:00.000Z'),
      );

      final decoded = WardrobeItem.fromJson(item.toJson());

      expect(decoded, isNotNull);
      expect(decoded!.id, item.id);
      expect(decoded.name, item.name);
      expect(decoded.imagePath, item.imagePath);
      expect(decoded.size, item.size);
      expect(decoded.createdAt.toUtc(), item.createdAt.toUtc());
    });

    test('returns null when required fields are missing', () {
      final decoded = WardrobeItem.fromJson(<String, dynamic>{
        'id': 'id-2',
        'name': 'Куртка',
      });

      expect(decoded, isNull);
    });
  });
}
