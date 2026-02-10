import 'package:ai_tryon/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserProfile', () {
    test('isComplete false when any field is missing', () {
      const profile = UserProfile(heightCm: 175, weightKg: 70);
      expect(profile.isComplete, isFalse);
      expect(profile.isValid, isFalse);
    });

    test('isValid true for values in range', () {
      const profile = UserProfile(
        heightCm: 180,
        weightKg: 75,
        gender: UserGender.male,
        ageYears: 28,
      );
      expect(profile.isComplete, isTrue);
      expect(profile.isValid, isTrue);
    });

    test('isValid false for out of range values', () {
      const profile = UserProfile(
        heightCm: 250,
        weightKg: 20,
        gender: UserGender.female,
        ageYears: 9,
      );
      expect(profile.isComplete, isTrue);
      expect(profile.isValid, isFalse);
    });
  });
}
