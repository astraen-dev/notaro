import "dart:async";
import "dart:ui";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_screenutil/flutter_screenutil.dart";
import "package:go_router/go_router.dart";
import "package:lucide_icons_flutter/lucide_icons.dart";
import "package:notaro_mobile/core/application/preferences_provider.dart";
import "package:notaro_mobile/core/ui/theme_provider.dart";
import "package:notaro_mobile/generated/l10n.dart";
import "package:notaro_mobile/shared/domain/user_preferences.dart";
import "package:package_info_plus/package_info_plus.dart";

class SettingsModal extends ConsumerWidget {
  const SettingsModal({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ThemeMode themeMode = ref.watch(themeModeProvider);
    final UserPreferences prefs =
        ref.watch(userPreferencesProvider).value ?? const UserPreferences();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.3,
      maxChildSize: 0.92,
      builder: (final context, final scrollController) => ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F172A).withValues(alpha: 0.8)
                  : const Color(0xFFF8FAFC).withValues(alpha: 0.85),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 48.h),
              physics: const ClampingScrollPhysics(),
              children: [
                // Handle Bar
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      S.of(context).settingsAppearance,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: Icon(LucideIcons.x, size: 20.sp),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),

                // --- Theme Selector ---
                _SectionLabel(label: S.of(context).settingsTheme),
                SizedBox(height: 12.h),

                // Theme Selector Buttons (Segmented Control style)
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFE2E8F0).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      _ThemeOption(
                        label: S.of(context).themeLight,
                        icon: LucideIcons.sun,
                        isActive: themeMode == ThemeMode.light,
                        onTap: () => ref
                            .read(themeModeProvider.notifier)
                            .setThemeMode(ThemeMode.light),
                      ),
                      _ThemeOption(
                        label: S.of(context).themeDark,
                        icon: LucideIcons.moon,
                        isActive: themeMode == ThemeMode.dark,
                        onTap: () => ref
                            .read(themeModeProvider.notifier)
                            .setThemeMode(ThemeMode.dark),
                      ),
                      _ThemeOption(
                        label: S.of(context).themeSystem,
                        icon: LucideIcons.monitor,
                        isActive: themeMode == ThemeMode.system,
                        onTap: () => ref
                            .read(themeModeProvider.notifier)
                            .setThemeMode(ThemeMode.system),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),

                // --- Accent Color Slider ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SectionLabel(label: S.of(context).settingsAccentColor),
                    const Spacer(),
                    // Hue Value Text
                    Text(
                      "${prefs.accentHue.toInt()}°",
                      style: TextStyle(
                        fontFamily: "monospace",
                        fontSize: 12.sp,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    // Live Preview Dot
                    Container(
                      width: 16.w,
                      height: 16.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: HSLColor.fromAHSL(
                          1,
                          prefs.accentHue,
                          0.8,
                          0.6,
                        ).toColor(),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                          width: 2.w,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),

                // --- Gradient Slider ---
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Gradient Background
                    Container(
                      height: 24.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFF0000), // 0
                            Color(0xFFFFFF00), // 60
                            Color(0xFF00FF00), // 120
                            Color(0xFF00FFFF), // 180
                            Color(0xFF0000FF), // 240
                            Color(0xFFFF00FF), // 300
                            Color(0xFFFF0000), // 360
                          ],
                        ),
                      ),
                    ),
                    // Slider Component
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 24.h,
                        trackShape: const RectangularSliderTrackShape(),
                        activeTrackColor: Colors.transparent,
                        inactiveTrackColor: Colors.transparent,
                        thumbColor: Colors.white,
                        thumbShape: RoundSliderThumbShape(
                          enabledThumbRadius: 12.r,
                          elevation: 4,
                        ),
                        overlayColor: Colors.transparent,
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 0,
                        ),
                      ),
                      child: Slider(
                        value: prefs.accentHue,
                        max: 360,
                        onChanged: (final value) {
                          unawaited(
                            ref
                                .read(userPreferencesProvider.notifier)
                                .setAccentHue(value),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24.h),

                // --- Typography Selector ---
                _SectionLabel(label: S.of(context).settingsTypography),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    _FontOption(
                      label: S.of(context).fontSans,
                      fontFamily: AppFontFamily.sans,
                      current: prefs.fontFamily,
                      onTap: () => ref
                          .read(userPreferencesProvider.notifier)
                          .setFontFamily(AppFontFamily.sans),
                    ),
                    SizedBox(width: 8.w),
                    _FontOption(
                      label: S.of(context).fontSerif,
                      fontFamily: AppFontFamily.serif,
                      current: prefs.fontFamily,
                      onTap: () => ref
                          .read(userPreferencesProvider.notifier)
                          .setFontFamily(AppFontFamily.serif),
                    ),
                    SizedBox(width: 8.w),
                    _FontOption(
                      label: S.of(context).fontMono,
                      fontFamily: AppFontFamily.mono,
                      current: prefs.fontFamily,
                      onTap: () => ref
                          .read(userPreferencesProvider.notifier)
                          .setFontFamily(AppFontFamily.mono),
                    ),
                  ],
                ),

                SizedBox(height: 40.h),
                Divider(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
                ),
                SizedBox(height: 24.h),

                // --- About Section (New) ---
                _SectionLabel(label: S.of(context).settingsAbout),
                SizedBox(height: 12.h),

                _SettingsTile(
                  icon: LucideIcons.share2,
                  label: S.of(context).settingsShare,
                  onTap: () {
                    // TODO: Implement share feature
                  },
                ),
                _SettingsTile(
                  icon: LucideIcons.star,
                  label: S.of(context).settingsRate,
                  onTap: () {
                    // TODO: Implement review feature
                  },
                ),
                _SettingsTile(
                  icon: LucideIcons.fileText,
                  label: S.of(context).settingsLicenses,
                  onTap: () {
                    unawaited(context.pushNamed("licenses"));
                  },
                ),

                SizedBox(height: 24.h),
                Center(
                  child: FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (final context, final snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        S.of(context).settingsVersion(snapshot.data!.version),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.4),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white.withValues(alpha: 0.5),
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20.sp, color: colorScheme.onSurface),
                SizedBox(width: 16.w),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Icon(
                  LucideIcons.chevronRight,
                  size: 16.sp,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(final BuildContext context) => Text(
    label,
    style: TextStyle(
      fontSize: 11.sp,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.sp,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: isActive
                ? (isDark ? const Color(0xFF334155) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8.r),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14.sp,
                color: isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FontOption extends StatelessWidget {
  const _FontOption({
    required this.label,
    required this.fontFamily,
    required this.current,
    required this.onTap,
  });

  final String label;
  final AppFontFamily fontFamily;
  final AppFontFamily current;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final bool isActive = fontFamily == current;
    final ThemeData theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: isActive
                ? (isDark
                      ? theme.colorScheme.primary.withValues(alpha: 0.2)
                      : theme.colorScheme.primary.withValues(alpha: 0.1))
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: isActive
                  ? theme.colorScheme.primary.withValues(alpha: 0.3)
                  : Colors.transparent,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
