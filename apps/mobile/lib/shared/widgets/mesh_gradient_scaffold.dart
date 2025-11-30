import "package:flutter/material.dart";

/// A Scaffold wrapper that renders the animated mesh gradient background
/// found in the desktop app (app.css).
class MeshGradientScaffold extends StatelessWidget {
  const MeshGradientScaffold({
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    super.key,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  @override
  Widget build(final BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Colors extracted from app.css mesh gradient
    // Light: accent (Purple/Indigo), Sky, Purple
    // Dark: Darker variants
    final Color accentColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF3F4F6),
      // Fallback base
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        children: [
          // 1. Mesh Gradients
          // Top Left
          Positioned(
            top: -100,
            left: -100,
            child: _BlurBlob(
              color: accentColor.withValues(alpha: isDark ? 0.15 : 0.25),
            ),
          ),
          // Top Right (Sky Blue-ish)
          Positioned(
            top: -50,
            right: -100,
            child: _BlurBlob(
              color: isDark
                  ? const Color(0xFF0C4A6E).withValues(alpha: 0.2)
                  : const Color(0xFF7DD3FC).withValues(alpha: 0.3),
            ),
          ),
          // Bottom Right (Purple-ish)
          Positioned(
            bottom: -100,
            right: -100,
            child: _BlurBlob(
              color: accentColor.withValues(alpha: isDark ? 0.1 : 0.2),
            ),
          ),
          // Bottom Left
          Positioned(
            bottom: 0,
            left: -50,
            child: _BlurBlob(
              color: isDark
                  ? const Color(0xFF581C87).withValues(alpha: 0.15)
                  : const Color(0xFFC084FC).withValues(alpha: 0.25),
            ),
          ),

          // 2. Content
          SafeArea(
            bottom: false,
            // If the navbar is translucent, we want body to go behind it?
            // For now, let's keep safe area top but allow bottom for scroll
            child: body,
          ),
        ],
      ),
    );
  }
}

class _BlurBlob extends StatelessWidget {
  const _BlurBlob({required this.color});

  final Color color;

  @override
  Widget build(final BuildContext context) => Container(
    width: 400,
    height: 400,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [color, color.withValues(alpha: 0)],
        stops: const [0.0, 0.7],
      ),
    ),
  );
}
