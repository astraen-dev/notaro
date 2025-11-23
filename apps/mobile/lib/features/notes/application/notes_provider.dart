import "package:notaro_mobile/features/notes/domain/note.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:uuid/uuid.dart";

part "notes_provider.g.dart";

const _uuid = Uuid();

@riverpod
class NotesNotifier extends _$NotesNotifier {
  @override
  List<Note> build() => [
    Note(
      id: _uuid.v4(),
      title: "Project Ideas",
      content:
          "1. Hyper-lightweight note app\n2. AI integration\n3. Cross-platform sync",
      updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      version: 1,
      isPinned: true,
    ),
    Note(
      id: _uuid.v4(),
      title: "Groceries",
      content: "Milk, Eggs, Bread, Coffee",
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      version: 1,
      folder: "Personal",
    ),
    Note(
      id: _uuid.v4(),
      title: "Meeting Notes",
      content: "Discussed Q3 roadmap. Key takeaways...",
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      version: 1,
      folder: "Work",
    ),
  ];

  void addNote() {
    final newNote = Note(
      id: _uuid.v4(),
      title: "",
      content: "",
      updatedAt: DateTime.now(),
      version: 1,
    );
    state = [newNote, ...state];
  }

  void updateNote(final String id, final String title, final String content) {
    state = [
      for (final note in state)
        if (note.id == id)
          note.copyWith(
            title: title,
            content: content,
            updatedAt: DateTime.now(),
          )
        else
          note,
    ];
  }

  void togglePin(final String id) {
    state = [
      for (final note in state)
        if (note.id == id) note.copyWith(isPinned: !note.isPinned) else note,
    ];
  }

  void deleteNote(final String id) {
    // Soft delete logic to match Desktop
    state = [
      for (final note in state)
        if (note.id == id) note.copyWith(isDeleted: true) else note,
    ];
  }
}
