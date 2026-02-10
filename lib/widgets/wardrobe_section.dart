import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/clothing_item.dart';
import '../providers/try_on_provider.dart';
import '../theme/app_theme.dart';

class WardrobeSection extends StatelessWidget {
  const WardrobeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TryOnProvider>();
    final items = provider.wardrobeItems;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.border),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Моя одежда',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _AddWardrobeItemSheet.show(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Добавить'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Добавьте фото вещи и выберите размер',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 14),
            if (items.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundSecondary,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Text(
                  'Список пуст. Нажмите «Добавить».',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              )
            else
              Column(
                children: items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _WardrobeCard(
                      item: item,
                      isSelected: provider.selectedWardrobeItemId == item.id,
                      onSelect: () => provider.selectWardrobeItem(item.id),
                      onDelete: () => provider.removeWardrobeItem(item.id),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _WardrobeCard extends StatelessWidget {
  final WardrobeItem item;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onDelete;

  const _WardrobeCard({
    required this.item,
    required this.isSelected,
    required this.onSelect,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final imageBytes = _previewBytesFromDataUri(item.imagePath);

    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.06)
              : AppTheme.backgroundSecondary,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              child: imageBytes != null
                  ? Image.memory(
                      imageBytes,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _brokenPreview();
                      },
                    )
                  : _brokenPreview(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Размер: ${item.size.label}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
            const SizedBox(width: 6),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _brokenPreview() {
    return Container(
      width: 64,
      height: 64,
      color: AppTheme.border,
      child: const Icon(
        Icons.broken_image_outlined,
        color: AppTheme.textSecondary,
      ),
    );
  }
}

class _AddWardrobeItemSheet extends StatefulWidget {
  const _AddWardrobeItemSheet();

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddWardrobeItemSheet(),
    );
  }

  @override
  State<_AddWardrobeItemSheet> createState() => _AddWardrobeItemSheetState();
}

class _AddWardrobeItemSheetState extends State<_AddWardrobeItemSheet> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();

  ClothingSize _selectedSize = ClothingSize.m;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 18 + inset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Добавить одежду',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              _PhotoPickerPreview(
                imageBytes: _selectedImageBytes,
                onPickGallery: () => _pickImage(ImageSource.gallery),
                onPickCamera: () => _pickImage(ImageSource.camera),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Название (опционально)',
                  filled: true,
                  fillColor: AppTheme.backgroundSecondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ClothingSize>(
                initialValue: _selectedSize,
                decoration: InputDecoration(
                  labelText: 'Размер',
                  filled: true,
                  fillColor: AppTheme.backgroundSecondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
                items: ClothingSize.values.map((size) {
                  return DropdownMenuItem<ClothingSize>(
                    value: size,
                    child: Text(size.label),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedSize = value);
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Сохранить'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final bool supportsCamera =
          !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS);
      final bool useGalleryFallback =
          source == ImageSource.camera && !supportsCamera;
      final effectiveSource = useGalleryFallback ? ImageSource.gallery : source;

      final file = await _picker.pickImage(
        source: effectiveSource,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 90,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось прочитать выбранное фото')),
        );
        return;
      }

      setState(() {
        _selectedImage = file;
        _selectedImageBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Не удалось выбрать фото: $e')));
    }
  }

  Future<void> _submit() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала выберите фото одежды')),
      );
      return;
    }

    setState(() => _saving = true);
    final error = await context.read<TryOnProvider>().addWardrobeItem(
      imageFile: _selectedImage!,
      size: _selectedSize,
      name: _nameController.text.trim(),
    );
    if (!mounted) return;

    setState(() => _saving = false);
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    Navigator.pop(context);
  }
}

class _PhotoPickerPreview extends StatelessWidget {
  final Uint8List? imageBytes;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;

  const _PhotoPickerPreview({
    required this.imageBytes,
    required this.onPickGallery,
    required this.onPickCamera,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          if (imageBytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              child: Image.memory(
                imageBytes!,
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 100,
                    alignment: Alignment.center,
                    child: const Text(
                      'Ошибка отображения фото',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  );
                },
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 100,
              alignment: Alignment.center,
              child: const Text(
                'Фото одежды не выбрано',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPickCamera,
                  icon: const Icon(Icons.camera_alt_rounded, size: 18),
                  label: const Text('Камера'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPickGallery,
                  icon: const Icon(Icons.photo_library_rounded, size: 18),
                  label: const Text('Файлы'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Uint8List? _previewBytesFromDataUri(String value) {
  if (!value.startsWith('data:')) return null;

  final commaIndex = value.indexOf(',');
  if (commaIndex < 0) return null;

  final header = value.substring(5, commaIndex);
  if (!header.contains(';base64')) return null;

  final payload = value.substring(commaIndex + 1);
  try {
    final bytes = base64Decode(payload);
    if (bytes.isEmpty) return null;
    return bytes;
  } catch (_) {
    return null;
  }
}
