import "package:flutter/material.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "theme_provider.g.dart";

@riverpod
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  ThemeMode build() => ThemeMode.system;

  void toggleTheme() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }

  void setSystem() {
    state = ThemeMode.system;
  }
}
