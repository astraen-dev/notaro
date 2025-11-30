import "package:go_router/go_router.dart";
import "package:notaro_mobile/features/editor/presentation/editor_screen.dart";
import "package:notaro_mobile/features/home/presentation/home_screen.dart";
import "package:notaro_mobile/features/settings/presentation/licenses_screen.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "app_router.g.dart";

@riverpod
GoRouter goRouter(final Ref ref) => GoRouter(
  initialLocation: "/",
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      path: "/",
      name: "home",
      builder: (final context, final state) => const HomeScreen(),
      routes: [
        GoRoute(
          path: "note/:id",
          name: "editor",
          builder: (final context, final state) {
            final String id = state.pathParameters["id"]!;
            return EditorScreen(noteId: id);
          },
        ),
        GoRoute(
          path: "licenses",
          name: "licenses",
          builder: (final context, final state) => const LicensesScreen(),
        ),
      ],
    ),
  ],
);
