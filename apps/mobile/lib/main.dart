import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_screenutil/flutter_screenutil.dart";
import "package:go_router/go_router.dart";
import "package:notaro_mobile/app_constants.dart";
import "package:notaro_mobile/core/navigation/app_router.dart";
import "package:notaro_mobile/core/ui/app_theme.dart";
import "package:notaro_mobile/core/ui/theme_provider.dart";

void main() {
  runApp(const ProviderScope(child: NotaroApp()));
}

class NotaroApp extends ConsumerWidget {
  const NotaroApp({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    // Watch the router provider
    final GoRouter goRouter = ref.watch(goRouterProvider);

    // Watch the theme mode provider
    final ThemeMode mode = ref.watch(themeModeProvider);

    return ScreenUtilInit(
      // Pixel 9 Pro dimensions as design baseline in dp
      designSize: const Size(427, 952),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (final context, final child) => MaterialApp.router(
        title: AppConstants.appName,
        routerConfig: goRouter,
        themeMode: mode,
        theme: AppTheme.light(context),
        darkTheme: AppTheme.dark(context),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
