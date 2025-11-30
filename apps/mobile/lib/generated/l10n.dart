// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Notaro`
  String get appName {
    return Intl.message(
      'Notaro',
      name: 'appName',
      desc: 'The name of the application.',
      args: [],
    );
  }

  /// `{count} chars`
  String editorCharCount(int count) {
    return Intl.message(
      '$count chars',
      name: 'editorCharCount',
      desc:
          'Label displayed at the bottom of the editor showing the total character count.',
      args: [count],
    );
  }

  /// `Start typing...`
  String get editorStartTyping {
    return Intl.message(
      'Start typing...',
      name: 'editorStartTyping',
      desc: 'Hint text displayed in the main editor content area when empty.',
      args: [],
    );
  }

  /// `All`
  String get filterAll {
    return Intl.message(
      'All',
      name: 'filterAll',
      desc: 'Label for the filter chip that shows all non-deleted notes.',
      args: [],
    );
  }

  /// `Pinned`
  String get filterPinned {
    return Intl.message(
      'Pinned',
      name: 'filterPinned',
      desc: 'Label for the filter chip that shows only pinned notes.',
      args: [],
    );
  }

  /// `Trash`
  String get filterTrash {
    return Intl.message(
      'Trash',
      name: 'filterTrash',
      desc: 'Label for the filter chip that shows deleted notes.',
      args: [],
    );
  }

  /// `Mono`
  String get fontMono {
    return Intl.message(
      'Mono',
      name: 'fontMono',
      desc: 'Label for the Monospace font family option.',
      args: [],
    );
  }

  /// `Sans Serif`
  String get fontSans {
    return Intl.message(
      'Sans Serif',
      name: 'fontSans',
      desc: 'Label for the Sans-Serif font family option.',
      args: [],
    );
  }

  /// `Serif`
  String get fontSerif {
    return Intl.message(
      'Serif',
      name: 'fontSerif',
      desc: 'Label for the Serif font family option.',
      args: [],
    );
  }

  /// `This application uses open-source software. The following list contains the libraries used, their versions, and their licenses.`
  String get licenseDisclaimerContent {
    return Intl.message(
      'This application uses open-source software. The following list contains the libraries used, their versions, and their licenses.',
      name: 'licenseDisclaimerContent',
      desc: 'Content body for the license disclaimer.',
      args: [],
    );
  }

  /// `Notices`
  String get licenseDisclaimerTitle {
    return Intl.message(
      'Notices',
      name: 'licenseDisclaimerTitle',
      desc: 'Title for the license disclaimer dialog.',
      args: [],
    );
  }

  /// `v{version}`
  String licensePackageVersion(String version) {
    return Intl.message(
      'v$version',
      name: 'licensePackageVersion',
      desc: 'Compact version label for license list items.',
      args: [version],
    );
  }

  /// `No matches found`
  String get noMatches {
    return Intl.message(
      'No matches found',
      name: 'noMatches',
      desc: 'Message displayed when a search query returns no results.',
      args: [],
    );
  }

  /// `No notes here`
  String get noNotes {
    return Intl.message(
      'No notes here',
      name: 'noNotes',
      desc:
          'Message displayed in the center of the screen when the note list is empty.',
      args: [],
    );
  }

  /// `No additional text`
  String get noteNoContent {
    return Intl.message(
      'No additional text',
      name: 'noteNoContent',
      desc:
          'Placeholder text displayed in the note preview card when the note body is empty.',
      args: [],
    );
  }

  /// `Untitled Note`
  String get noteUntitled {
    return Intl.message(
      'Untitled Note',
      name: 'noteUntitled',
      desc:
          'Default title displayed for a note that has no user-defined title.',
      args: [],
    );
  }

  /// `OK`
  String get okButtonLabel {
    return Intl.message(
      'OK',
      name: 'okButtonLabel',
      desc: 'Standard confirmation button label.',
      args: [],
    );
  }

  /// `Search notes...`
  String get searchHint {
    return Intl.message(
      'Search notes...',
      name: 'searchHint',
      desc: 'Placeholder text displayed inside the search bar.',
      args: [],
    );
  }

  /// `ABOUT`
  String get settingsAbout {
    return Intl.message(
      'ABOUT',
      name: 'settingsAbout',
      desc: 'Section header for the about/info section in settings.',
      args: [],
    );
  }

  /// `ACCENT COLOR`
  String get settingsAccentColor {
    return Intl.message(
      'ACCENT COLOR',
      name: 'settingsAccentColor',
      desc: 'Section header for the accent color slider.',
      args: [],
    );
  }

  /// `Appearance`
  String get settingsAppearance {
    return Intl.message(
      'Appearance',
      name: 'settingsAppearance',
      desc: 'Title text displayed at the top of the Settings modal.',
      args: [],
    );
  }

  /// `Open Source Licenses`
  String get settingsLicenses {
    return Intl.message(
      'Open Source Licenses',
      name: 'settingsLicenses',
      desc: 'Button label to view open source licenses.',
      args: [],
    );
  }

  /// `Rate & Review`
  String get settingsRate {
    return Intl.message(
      'Rate & Review',
      name: 'settingsRate',
      desc: 'Button label to rate the app on the store.',
      args: [],
    );
  }

  /// `Share Notaro`
  String get settingsShare {
    return Intl.message(
      'Share Notaro',
      name: 'settingsShare',
      desc: 'Button label to share the app.',
      args: [],
    );
  }

  /// `THEME`
  String get settingsTheme {
    return Intl.message(
      'THEME',
      name: 'settingsTheme',
      desc: 'Section header for the theme selection controls.',
      args: [],
    );
  }

  /// `TYPOGRAPHY`
  String get settingsTypography {
    return Intl.message(
      'TYPOGRAPHY',
      name: 'settingsTypography',
      desc: 'Section header for the font family selection controls.',
      args: [],
    );
  }

  /// `Version {version}`
  String settingsVersion(String version) {
    return Intl.message(
      'Version $version',
      name: 'settingsVersion',
      desc: 'Label showing the current app version.',
      args: [version],
    );
  }

  /// `Dark`
  String get themeDark {
    return Intl.message(
      'Dark',
      name: 'themeDark',
      desc: 'Label for the dark theme option in the settings.',
      args: [],
    );
  }

  /// `Light`
  String get themeLight {
    return Intl.message(
      'Light',
      name: 'themeLight',
      desc: 'Label for the light theme option in the settings.',
      args: [],
    );
  }

  /// `System`
  String get themeSystem {
    return Intl.message(
      'System',
      name: 'themeSystem',
      desc: 'Label for the system-default theme option in the settings.',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[Locale.fromSubtags(languageCode: 'en')];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
