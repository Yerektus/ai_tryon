import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_profile.dart';
import '../providers/try_on_provider.dart';
import '../theme/app_theme.dart';

class UserProfileSection extends StatefulWidget {
  const UserProfileSection({super.key});

  @override
  State<UserProfileSection> createState() => _UserProfileSectionState();
}

class _UserProfileSectionState extends State<UserProfileSection> {
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _ageController;

  late final FocusNode _heightFocusNode;
  late final FocusNode _weightFocusNode;
  late final FocusNode _ageFocusNode;

  bool _didInitFromProvider = false;

  @override
  void initState() {
    super.initState();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _ageController = TextEditingController();

    _heightFocusNode = FocusNode();
    _weightFocusNode = FocusNode();
    _ageFocusNode = FocusNode();

    _heightController.addListener(_pushProfileUpdate);
    _weightController.addListener(_pushProfileUpdate);
    _ageController.addListener(_pushProfileUpdate);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInitFromProvider) {
      _syncControllers(context.read<TryOnProvider>().profile, force: true);
      _didInitFromProvider = true;
    }
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    _heightFocusNode.dispose();
    _weightFocusNode.dispose();
    _ageFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<TryOnProvider>().profile;
    _syncControllers(profile);

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
            const Text(
              'Параметры профиля',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Нужны для более точной примерки',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _NumberField(
                    controller: _heightController,
                    focusNode: _heightFocusNode,
                    label: 'Рост (см)',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NumberField(
                    controller: _weightController,
                    focusNode: _weightFocusNode,
                    label: 'Вес (кг)',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _NumberField(
                    controller: _ageController,
                    focusNode: _ageFocusNode,
                    label: 'Возраст',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _GenderSelector(
                    selected: profile.gender,
                    onSelect: _onGenderSelected,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _validationHint(profile),
              style: TextStyle(
                fontSize: 12,
                color: profile.isValid
                    ? AppTheme.success
                    : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onGenderSelected(UserGender gender) {
    final provider = context.read<TryOnProvider>();
    provider.updateProfile(
      heightCm: _parseNullableInt(_heightController.text),
      weightKg: _parseNullableInt(_weightController.text),
      ageYears: _parseNullableInt(_ageController.text),
      gender: gender,
    );
  }

  void _pushProfileUpdate() {
    final provider = context.read<TryOnProvider>();
    provider.updateProfile(
      heightCm: _parseNullableInt(_heightController.text),
      weightKg: _parseNullableInt(_weightController.text),
      ageYears: _parseNullableInt(_ageController.text),
      gender: provider.profile.gender,
    );
  }

  void _syncControllers(UserProfile profile, {bool force = false}) {
    _syncControllerValue(
      controller: _heightController,
      focusNode: _heightFocusNode,
      value: profile.heightCm?.toString() ?? '',
      force: force,
    );
    _syncControllerValue(
      controller: _weightController,
      focusNode: _weightFocusNode,
      value: profile.weightKg?.toString() ?? '',
      force: force,
    );
    _syncControllerValue(
      controller: _ageController,
      focusNode: _ageFocusNode,
      value: profile.ageYears?.toString() ?? '',
      force: force,
    );
  }

  void _syncControllerValue({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String value,
    required bool force,
  }) {
    if (!force && focusNode.hasFocus) return;
    if (controller.text == value) return;
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  int? _parseNullableInt(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }

  String _validationHint(UserProfile profile) {
    if (profile.isValid) {
      return 'Профиль заполнен';
    }
    if (!profile.isComplete) {
      return 'Заполните рост, вес, пол и возраст';
    }
    return 'Диапазоны: рост 120-230, вес 35-250, возраст 12-90';
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;

  const _NumberField({
    required this.controller,
    required this.focusNode,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppTheme.backgroundSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: const BorderSide(color: AppTheme.primary),
        ),
      ),
    );
  }
}

class _GenderSelector extends StatelessWidget {
  final UserGender? selected;
  final ValueChanged<UserGender> onSelect;

  const _GenderSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ChoiceChip(
            label: const Text('М'),
            selected: selected == UserGender.male,
            onSelected: (value) {
              if (!value) return;
              onSelect(UserGender.male);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ChoiceChip(
            label: const Text('Ж'),
            selected: selected == UserGender.female,
            onSelected: (value) {
              if (!value) return;
              onSelect(UserGender.female);
            },
          ),
        ),
      ],
    );
  }
}
