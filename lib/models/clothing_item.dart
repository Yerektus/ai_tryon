enum ClothingSize {
  xxs,
  xs,
  s,
  m,
  l,
  xl,
  xxl,
  xxxl,
  eu40,
  eu42,
  eu44,
  eu46,
  eu48,
  eu50,
  eu52,
  eu54,
  eu56,
  eu58,
}

extension ClothingSizeX on ClothingSize {
  String get label {
    switch (this) {
      case ClothingSize.xxs:
        return 'XXS';
      case ClothingSize.xs:
        return 'XS';
      case ClothingSize.s:
        return 'S';
      case ClothingSize.m:
        return 'M';
      case ClothingSize.l:
        return 'L';
      case ClothingSize.xl:
        return 'XL';
      case ClothingSize.xxl:
        return 'XXL';
      case ClothingSize.xxxl:
        return 'XXXL';
      case ClothingSize.eu40:
        return 'EU 40';
      case ClothingSize.eu42:
        return 'EU 42';
      case ClothingSize.eu44:
        return 'EU 44';
      case ClothingSize.eu46:
        return 'EU 46';
      case ClothingSize.eu48:
        return 'EU 48';
      case ClothingSize.eu50:
        return 'EU 50';
      case ClothingSize.eu52:
        return 'EU 52';
      case ClothingSize.eu54:
        return 'EU 54';
      case ClothingSize.eu56:
        return 'EU 56';
      case ClothingSize.eu58:
        return 'EU 58';
    }
  }

  String get storageValue => name;

  static ClothingSize? fromStorage(String? value) {
    if (value == null) return null;
    for (final size in ClothingSize.values) {
      if (size.name == value) return size;
    }
    return null;
  }
}

/// User-added clothing item stored locally for try-on.
class WardrobeItem {
  final String id;
  final String name;
  final String imagePath;
  final ClothingSize size;
  final DateTime createdAt;

  const WardrobeItem({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.size,
    required this.createdAt,
  });

  WardrobeItem copyWith({
    String? id,
    String? name,
    String? imagePath,
    ClothingSize? size,
    DateTime? createdAt,
  }) {
    return WardrobeItem(
      id: id ?? this.id,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      size: size ?? this.size,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'imagePath': imagePath,
      'size': size.storageValue,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static WardrobeItem? fromJson(Map<String, dynamic> json) {
    final size = ClothingSizeX.fromStorage(json['size'] as String?);
    final createdAtRaw = json['createdAt'] as String?;
    final createdAt = createdAtRaw == null
        ? null
        : DateTime.tryParse(createdAtRaw);
    if (size == null || createdAt == null) return null;

    final id = json['id'] as String?;
    final name = json['name'] as String?;
    final imagePath = json['imagePath'] as String?;
    if (id == null || name == null || imagePath == null) return null;

    return WardrobeItem(
      id: id,
      name: name,
      imagePath: imagePath,
      size: size,
      createdAt: createdAt,
    );
  }
}
