enum UserGender { male, female }

extension UserGenderX on UserGender {
  String get label {
    switch (this) {
      case UserGender.male:
        return 'Мужской';
      case UserGender.female:
        return 'Женский';
    }
  }

  String get storageValue => name;

  static UserGender? fromStorage(String? value) {
    if (value == null) return null;
    for (final gender in UserGender.values) {
      if (gender.name == value) return gender;
    }
    return null;
  }
}

class UserProfile {
  final int? heightCm;
  final int? weightKg;
  final UserGender? gender;
  final int? ageYears;

  const UserProfile({this.heightCm, this.weightKg, this.gender, this.ageYears});

  const UserProfile.empty()
    : heightCm = null,
      weightKg = null,
      gender = null,
      ageYears = null;

  bool get isComplete =>
      heightCm != null &&
      weightKg != null &&
      gender != null &&
      ageYears != null;

  bool get isValid {
    if (!isComplete) return false;
    return heightCm! >= 120 &&
        heightCm! <= 230 &&
        weightKg! >= 35 &&
        weightKg! <= 250 &&
        ageYears! >= 12 &&
        ageYears! <= 90;
  }

  UserProfile copyWith({
    int? heightCm,
    int? weightKg,
    UserGender? gender,
    int? ageYears,
    bool clearHeight = false,
    bool clearWeight = false,
    bool clearGender = false,
    bool clearAge = false,
  }) {
    return UserProfile(
      heightCm: clearHeight ? null : (heightCm ?? this.heightCm),
      weightKg: clearWeight ? null : (weightKg ?? this.weightKg),
      gender: clearGender ? null : (gender ?? this.gender),
      ageYears: clearAge ? null : (ageYears ?? this.ageYears),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'heightCm': heightCm,
      'weightKg': weightKg,
      'gender': gender?.storageValue,
      'ageYears': ageYears,
    };
  }

  static UserProfile fromJson(Map<String, dynamic> json) {
    return UserProfile(
      heightCm: json['heightCm'] as int?,
      weightKg: json['weightKg'] as int?,
      gender: UserGenderX.fromStorage(json['gender'] as String?),
      ageYears: json['ageYears'] as int?,
    );
  }
}
