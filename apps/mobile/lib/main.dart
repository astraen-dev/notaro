import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_screenutil/flutter_screenutil.dart";
import "package:go_router/go_router.dart";
import "package:notaro_mobile/app_constants.dart";
import "package:notaro_mobile/core/application/preferences_provider.dart";
import "package:notaro_mobile/core/navigation/app_router.dart";
import "package:notaro_mobile/core/ui/app_theme.dart";
import "package:notaro_mobile/core/ui/theme_provider.dart";
import "package:notaro_mobile/shared/domain/user_preferences.dart";

void main() {
  runApp(const ProviderScope(child: NotaroApp()));
}

class NotaroApp extends ConsumerWidget {
  const NotaroApp({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    // Watch the router provider
    final GoRouter goRouter = ref.watch(goRouterProvider);

    // Watch the theme mode provider (System/Light/Dark)
    final ThemeMode mode = ref.watch(themeModeProvider);

    // Watch full prefs for Accent/Font
    final UserPreferences prefs =
        ref.watch(userPreferencesProvider).value ?? const UserPreferences();

    return ScreenUtilInit(
      // Pixel 9 Pro dimensions as design baseline in dp
      designSize: const Size(427, 952),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (final context, final child) => MaterialApp.router(
        title: AppConstants.appName,
        routerConfig: goRouter,
        themeMode: mode,
        // Pass dynamic preferences to theme builder
        theme: AppTheme.light(context, prefs.accentHue, prefs.fontFamily),
        darkTheme: AppTheme.dark(context, prefs.accentHue, prefs.fontFamily),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
