import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/try_on_provider.dart';
import '../theme/app_theme.dart';

/// Full-screen result viewer with before / after swipe comparison.
class ResultView extends StatelessWidget {
  const ResultView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TryOnProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Swipeable before / after
          PageView(
            onPageChanged: (_) {
              HapticFeedback.selectionClick();
              provider.toggleBeforeAfter();
            },
            children: [
              // "Before" — original user photo
              _ImagePage(
                label: 'До',
                child: provider.userPhotoBytes != null
                    ? Hero(
                        tag: 'user-photo',
                        child: Image.memory(
                          provider.userPhotoBytes!,
                          fit: BoxFit.contain,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              // "After" — AI result
              _ImagePage(
                label: 'После',
                child: provider.resultImageBytes != null
                    ? Image.memory(
                        provider.resultImageBytes!,
                        fit: BoxFit.contain,
                      )
                    : provider.resultImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: provider.resultImageUrl!,
                        fit: BoxFit.contain,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),

          // Top controls
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CircleButton(
                      icon: Icons.close_rounded,
                      onTap: () => provider.resetResult(),
                    ),
                    // Swipe hint
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.swipe_rounded,
                            color: Colors.white.withValues(alpha: 0.8),
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            provider.showBefore ? 'До' : 'После',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 44), // balance
                  ],
                ),
              ),
            ),
          ),

          // Bottom action bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.download_rounded,
                        label: 'Сохранить',
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _showToast(context, 'Сохранено в галерею');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.share_rounded,
                        label: 'Поделиться',
                        isPrimary: true,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _showToast(context, 'Подготовка к отправке…');
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        backgroundColor: AppTheme.textPrimary,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 80),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// A single full-screen image with a label badge.
class _ImagePage extends StatelessWidget {
  final String label;
  final Widget child;

  const _ImagePage({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(child: child),
        // Label badge
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Translucent circle icon button.
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

/// Styled action button (solid or outline).
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isPrimary
              ? Colors.white
              : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: isPrimary
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isPrimary ? AppTheme.textPrimary : Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isPrimary ? AppTheme.textPrimary : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
