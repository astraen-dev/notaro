// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'en';

  static String m0(count) => "${count} chars";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "appName": MessageLookupByLibrary.simpleMessage("Notaro"),
    "editorCharCount": m0,
    "editorStartTyping": MessageLookupByLibrary.simpleMessage(
      "Start typing...",
    ),
    "filterAll": MessageLookupByLibrary.simpleMessage("All"),
    "filterPinned": MessageLookupByLibrary.simpleMessage("Pinned"),
    "filterTrash": MessageLookupByLibrary.simpleMessage("Trash"),
    "fontMono": MessageLookupByLibrary.simpleMessage("Mono"),
    "fontSans": MessageLookupByLibrary.simpleMessage("Sans Serif"),
    "fontSerif": MessageLookupByLibrary.simpleMessage("Serif"),
    "noMatches": MessageLookupByLibrary.simpleMessage("No matches found"),
    "noNotes": MessageLookupByLibrary.simpleMessage("No notes here"),
    "noteNoContent": MessageLookupByLibrary.simpleMessage("No additional text"),
    "noteUntitled": MessageLookupByLibrary.simpleMessage("Untitled Note"),
    "searchHint": MessageLookupByLibrary.simpleMessage("Search notes..."),
    "settingsAccentColor": MessageLookupByLibrary.simpleMessage("ACCENT COLOR"),
    "settingsAppearance": MessageLookupByLibrary.simpleMessage("Appearance"),
    "settingsTheme": MessageLookupByLibrary.simpleMessage("THEME"),
    "settingsTypography": MessageLookupByLibrary.simpleMessage("TYPOGRAPHY"),
    "themeDark": MessageLookupByLibrary.simpleMessage("Dark"),
    "themeLight": MessageLookupByLibrary.simpleMessage("Light"),
    "themeSystem": MessageLookupByLibrary.simpleMessage("System"),
  };
}
