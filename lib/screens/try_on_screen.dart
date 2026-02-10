import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/try_on_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/hero_photo_section.dart';
import '../widgets/user_profile_section.dart';
import '../widgets/wardrobe_section.dart';
import '../widgets/try_on_button.dart';
import '../widgets/result_view.dart';

/// Main screen for the AI virtual try-on experience.
class TryOnScreen extends StatefulWidget {
  const TryOnScreen({super.key});

  @override
  State<TryOnScreen> createState() => _TryOnScreenState();
}

class _TryOnScreenState extends State<TryOnScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TryOnProvider>();

    // Show full-screen result view when a try-on result is available.
    if (provider.state == TryOnState.result) {
      return const ResultView();
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: _buildAppBar(context),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: provider.state == TryOnState.processing
            ? _buildProcessingState()
            : _buildMainContent(provider),
      ),
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      toolbarHeight: 56,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryDark],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          const Text('AI Примерка'),
        ],
      ),
      actions: [
        GestureDetector(
          onTap: () => HapticFeedback.lightImpact(),
          child: Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundSecondary,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.border, width: 1),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              size: 20,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  // ── Main content ──────────────────────────────────────────────────
  Widget _buildMainContent(TryOnProvider provider) {
    final bool canTryOn = provider.canTryOn;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // Hero photo section
                const HeroPhotoSection(),
                const SizedBox(height: 28),
                // User profile
                const UserProfileSection(),
                const SizedBox(height: 24),
                // Wardrobe
                const WardrobeSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // Sticky bottom button
        Container(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: TryOnButton(
              onPressed: canTryOn
                  ? () async {
                      final error = await provider.startTryOn();
                      if (!mounted || error == null) return;
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(error)));
                    }
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  // ── Processing state ──────────────────────────────────────────────
  Widget _buildProcessingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated pulse ring
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.2),
                    AppTheme.primary.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: const Center(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'AI обрабатывает фото…',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Это займёт несколько секунд',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
