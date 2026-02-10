import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/clothing_item.dart';
import '../models/user_profile.dart';
import '../services/openai_try_on_service.dart';

/// Possible states for the try-on flow.
enum TryOnState { idle, photoLoaded, processing, result }

/// Central state management for the AI try-on feature.
class TryOnProvider extends ChangeNotifier {
  TryOnProvider({OpenAiTryOnService? tryOnService})
    : _tryOnService = tryOnService ?? OpenAiTryOnService() {
    unawaited(loadLocalData());
  }

  static const String _openAiApiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const String _openAiModel = String.fromEnvironment(
    'OPENAI_MODEL',
    defaultValue: String.fromEnvironment(
      'OPENAI_IMAGE_MODEL',
      defaultValue: 'gpt-4.1',
    ),
  );

  static const String _profileStorageKey = 'profile_v1';
  static const String _wardrobeStorageKey = 'wardrobe_v1';
  static const String _selectedWardrobeStorageKey = 'wardrobe_selected_v1';

  final ImagePicker _picker = ImagePicker();
  final OpenAiTryOnService _tryOnService;

  TryOnState _state = TryOnState.idle;
  TryOnState get state => _state;

  Uint8List? _userPhotoBytes;
  Uint8List? get userPhotoBytes => _userPhotoBytes;
  String? _userPhotoMimeType;

  String? _resultImageUrl;
  String? get resultImageUrl => _resultImageUrl;

  Uint8List? _resultImageBytes;
  Uint8List? get resultImageBytes => _resultImageBytes;

  UserProfile _profile = const UserProfile.empty();
  UserProfile get profile => _profile;

  final List<WardrobeItem> _wardrobeItems = <WardrobeItem>[];
  List<WardrobeItem> get wardrobeItems =>
      List<WardrobeItem>.unmodifiable(_wardrobeItems);

  String? _selectedWardrobeItemId;
  String? get selectedWardrobeItemId => _selectedWardrobeItemId;

  WardrobeItem? get selectedWardrobeItem {
    final selectedId = _selectedWardrobeItemId;
    if (selectedId == null) return null;
    for (final item in _wardrobeItems) {
      if (item.id == selectedId) return item;
    }
    return null;
  }

  bool _showBefore = true;
  bool get showBefore => _showBefore;

  bool get canTryOn {
    return _userPhotoBytes != null &&
        selectedWardrobeItem != null &&
        _profile.isComplete &&
        _profile.isValid;
  }

  // ── Persistence ────────────────────────────────────────────────────────

  Future<void> loadLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final profileRaw = prefs.getString(_profileStorageKey);
      if (profileRaw != null) {
        final dynamic decoded = jsonDecode(profileRaw);
        if (decoded is Map) {
          _profile = UserProfile.fromJson(Map<String, dynamic>.from(decoded));
        }
      }

      final List<WardrobeItem> loadedItems = <WardrobeItem>[];
      final wardrobeRaw = prefs.getString(_wardrobeStorageKey);
      if (wardrobeRaw != null) {
        final dynamic decoded = jsonDecode(wardrobeRaw);
        if (decoded is List<dynamic>) {
          for (final dynamic item in decoded) {
            if (item is! Map) continue;
            final parsed = WardrobeItem.fromJson(
              Map<String, dynamic>.from(item),
            );
            if (parsed != null) {
              loadedItems.add(parsed);
            }
          }
        }
      }

      final List<WardrobeItem> normalizedItems = <WardrobeItem>[];
      bool hasStorageChanges = false;
      for (final item in loadedItems) {
        final normalized = await _normalizeWardrobeItemImage(item);
        if (normalized == null) {
          hasStorageChanges = true;
          continue;
        }

        if (normalized.imagePath != item.imagePath) {
          hasStorageChanges = true;
        }
        normalizedItems.add(normalized);
      }

      _wardrobeItems
        ..clear()
        ..addAll(normalizedItems);

      final savedSelectedId = prefs.getString(_selectedWardrobeStorageKey);
      if (savedSelectedId != null &&
          _wardrobeItems.any((item) => item.id == savedSelectedId)) {
        _selectedWardrobeItemId = savedSelectedId;
      } else {
        _selectedWardrobeItemId = _wardrobeItems.isNotEmpty
            ? _wardrobeItems.first.id
            : null;
      }

      if (hasStorageChanges) {
        unawaited(saveLocalData());
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load local data: $e');
    }
  }

  Future<void> saveLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileStorageKey, jsonEncode(_profile.toJson()));
    await prefs.setString(
      _wardrobeStorageKey,
      jsonEncode(_wardrobeItems.map((item) => item.toJson()).toList()),
    );

    if (_selectedWardrobeItemId == null) {
      await prefs.remove(_selectedWardrobeStorageKey);
    } else {
      await prefs.setString(
        _selectedWardrobeStorageKey,
        _selectedWardrobeItemId!,
      );
    }
  }

  // ── Profile ────────────────────────────────────────────────────────────

  void updateProfile({
    required int? heightCm,
    required int? weightKg,
    required UserGender? gender,
    required int? ageYears,
  }) {
    _profile = UserProfile(
      heightCm: heightCm,
      weightKg: weightKg,
      gender: gender,
      ageYears: ageYears,
    );
    unawaited(saveLocalData());
    notifyListeners();
  }

  // ── User Photo ─────────────────────────────────────────────────────────

  /// Opens camera or gallery to pick a user photo.
  Future<String?> pickPhoto(ImageSource source) async {
    try {
      final bool useGalleryFallback =
          source == ImageSource.camera && !_supportsCameraSource;
      final ImageSource effectiveSource = useGalleryFallback
          ? ImageSource.gallery
          : source;

      if (useGalleryFallback) {
        debugPrint(
          'Camera is not supported on this platform, opening gallery instead.',
        );
      }

      final XFile? image = await _picker.pickImage(
        source: effectiveSource,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 90,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        if (bytes.isEmpty) {
          return 'Не удалось прочитать фотографию';
        }

        _userPhotoBytes = bytes;
        _userPhotoMimeType = _detectMimeTypeFromPath(image.path);
        _state = TryOnState.photoLoaded;
        notifyListeners();
        return null;
      }

      return 'Фотография не выбрана';
    } catch (e) {
      debugPrint('Image picker error: $e');
      return 'Не удалось загрузить фотографию. Проверьте доступ к файлам/галерее.';
    }
  }

  /// Removes the current user photo and resets to idle.
  void removePhoto() {
    _userPhotoBytes = null;
    _userPhotoMimeType = null;
    _state = TryOnState.idle;
    _resultImageUrl = null;
    _resultImageBytes = null;
    notifyListeners();
  }

  // ── Wardrobe ───────────────────────────────────────────────────────────

  Future<String?> addWardrobeItem({
    required XFile imageFile,
    required ClothingSize size,
    String? name,
  }) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      if (imageBytes.isEmpty) {
        return 'Не удалось прочитать файл одежды';
      }

      final String id = DateTime.now().millisecondsSinceEpoch.toString();
      final String mimeType = _detectMimeTypeFromPath(imageFile.path);
      final String dataUri = _toDataUri(imageBytes, mimeType);

      final String itemName = (name == null || name.trim().isEmpty)
          ? 'Вещь ${_wardrobeItems.length + 1}'
          : name.trim();

      final item = WardrobeItem(
        id: id,
        name: itemName,
        imagePath: dataUri,
        size: size,
        createdAt: DateTime.now(),
      );

      _wardrobeItems.insert(0, item);
      _selectedWardrobeItemId = item.id;

      await saveLocalData();
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('Add wardrobe item error: $e');
      return 'Не удалось добавить одежду. Попробуйте другое фото.';
    }
  }

  void removeWardrobeItem(String id) {
    final index = _wardrobeItems.indexWhere((item) => item.id == id);
    if (index < 0) return;

    _wardrobeItems.removeAt(index);
    if (_selectedWardrobeItemId == id) {
      _selectedWardrobeItemId = _wardrobeItems.isNotEmpty
          ? _wardrobeItems.first.id
          : null;
    }

    unawaited(saveLocalData());
    notifyListeners();
  }

  void selectWardrobeItem(String id) {
    if (!_wardrobeItems.any((item) => item.id == id)) return;
    _selectedWardrobeItemId = id;
    unawaited(saveLocalData());
    notifyListeners();
  }

  // ── Try-On Processing ─────────────────────────────────────────────────

  /// Runs the AI virtual try-on generation.
  Future<String?> startTryOn() async {
    final selectedItem = selectedWardrobeItem;
    if (_userPhotoBytes == null || selectedItem == null) {
      return 'Загрузите фото и добавьте одежду для примерки';
    }
    if (!_profile.isComplete || !_profile.isValid) {
      return 'Заполните корректно рост, вес, пол и возраст';
    }
    if (_openAiApiKey.isEmpty) {
      return 'Добавьте OPENAI_API_KEY через --dart-define для запуска AI примерки';
    }

    final clothingImage = await _resolveWardrobeImage(selectedItem);
    if (clothingImage == null) {
      removeWardrobeItem(selectedItem.id);
      return 'Файл выбранной одежды не найден. Добавьте одежду снова.';
    }

    _state = TryOnState.processing;
    notifyListeners();

    try {
      final modelToUse = _openAiModel.toLowerCase().startsWith('dall-e')
          ? 'gpt-4.1'
          : _openAiModel;

      final resultBytes = await _tryOnService.generateTryOn(
        apiKey: _openAiApiKey,
        model: modelToUse,
        personPhotoBytes: _userPhotoBytes!,
        personPhotoMimeType: _userPhotoMimeType ?? 'image/jpeg',
        clothingPhotoBytes: clothingImage.bytes,
        clothingPhotoMimeType: clothingImage.mimeType,
        clothingSize: selectedItem.size,
        clothingName: selectedItem.name,
        heightCm: _profile.heightCm!,
        weightKg: _profile.weightKg!,
        gender: _profile.gender!,
        ageYears: _profile.ageYears!,
      );

      _resultImageBytes = resultBytes;
      _resultImageUrl = null;
      _state = TryOnState.result;
      _showBefore = false;
      notifyListeners();
      return null;
    } on TryOnException catch (e) {
      _state = _baseState();
      notifyListeners();
      return e.message;
    } catch (e) {
      _state = _baseState();
      notifyListeners();
      debugPrint('Try-on error: $e');
      return 'Не удалось выполнить AI примерку. Попробуйте еще раз.';
    }
  }

  /// Toggles the before / after comparison view.
  void toggleBeforeAfter() {
    _showBefore = !_showBefore;
    notifyListeners();
  }

  /// Resets back to the main screen keeping the photo.
  void resetResult() {
    _state = _baseState();
    _resultImageUrl = null;
    _resultImageBytes = null;
    _showBefore = true;
    notifyListeners();
  }

  /// Full reset — clears everything.
  void resetAll() {
    _state = TryOnState.idle;
    _userPhotoBytes = null;
    _userPhotoMimeType = null;
    _wardrobeItems.clear();
    _selectedWardrobeItemId = null;
    _profile = const UserProfile.empty();
    _resultImageUrl = null;
    _resultImageBytes = null;
    _showBefore = true;

    unawaited(_clearLocalData());
    notifyListeners();
  }

  TryOnState _baseState() =>
      _userPhotoBytes != null ? TryOnState.photoLoaded : TryOnState.idle;

  bool get _supportsCameraSource =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<WardrobeItem?> _normalizeWardrobeItemImage(WardrobeItem item) async {
    final existingDataUri = _decodeDataUri(item.imagePath);
    if (existingDataUri != null) {
      return item;
    }

    final migratedImage = await _readImageFromPath(item.imagePath);
    if (migratedImage == null) {
      return null;
    }

    return item.copyWith(
      imagePath: _toDataUri(migratedImage.bytes, migratedImage.mimeType),
    );
  }

  Future<_BinaryImage?> _resolveWardrobeImage(WardrobeItem item) async {
    final dataUri = _decodeDataUri(item.imagePath);
    if (dataUri != null) {
      return dataUri;
    }

    return _readImageFromPath(item.imagePath);
  }

  Future<_BinaryImage?> _readImageFromPath(String path) async {
    try {
      final bytes = await XFile(path).readAsBytes();
      if (bytes.isEmpty) return null;

      return _BinaryImage(
        bytes: bytes,
        mimeType: _detectMimeTypeFromPath(path),
      );
    } catch (_) {
      return null;
    }
  }

  String _detectMimeTypeFromPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  String _toDataUri(Uint8List bytes, String mimeType) {
    return 'data:$mimeType;base64,${base64Encode(bytes)}';
  }

  _BinaryImage? _decodeDataUri(String value) {
    if (!value.startsWith('data:')) return null;

    final commaIndex = value.indexOf(',');
    if (commaIndex < 0) return null;

    final header = value.substring(5, commaIndex);
    if (!header.contains(';base64')) return null;

    final mimeType = header.split(';').first;
    final payload = value.substring(commaIndex + 1);

    try {
      final bytes = base64Decode(payload);
      if (bytes.isEmpty) return null;
      return _BinaryImage(
        bytes: bytes,
        mimeType: mimeType.isEmpty ? 'image/jpeg' : mimeType,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _clearLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileStorageKey);
    await prefs.remove(_wardrobeStorageKey);
    await prefs.remove(_selectedWardrobeStorageKey);
  }
}

class _BinaryImage {
  final Uint8List bytes;
  final String mimeType;

  const _BinaryImage({required this.bytes, required this.mimeType});
}
