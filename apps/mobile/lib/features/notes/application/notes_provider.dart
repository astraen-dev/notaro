import "dart:async";
import "package:notaro_mobile/features/notes/domain/note.dart";
import "package:notaro_mobile/rust/api/native.dart" as rust_api;
import "package:riverpod_annotation/riverpod_annotation.dart";

part "notes_provider.g.dart";

@riverpod
class NotesNotifier extends _$NotesNotifier {
  @override
  Future<List<Note>> build() async {
    final List<rust_api.Note> rustNotes = await rust_api.getAllNotes();

    return rustNotes
        .map(
          (final n) => Note(
            id: n.id,
            title: n.title,
            content: n.content,
            updatedAt: DateTime.parse(n.updatedAt),
            version: n.version,
            folder: n.folder,
            isPinned: n.isPinned,
            isDeleted: n.isDeleted,
          ),
        )
        .toList();
  }

  Future<void> addNote() async {
    await rust_api.createNote(title: "", content: "");
    ref.invalidateSelf();
  }

  Future<void> updateNote(
    final String id,
    final String title,
    final String content, {
    final String? folder,
  }) async {
    final List<Note> currentList = state.value ?? [];
    final Note oldNote = currentList.firstWhere((final n) => n.id == id);

    await rust_api.updateNote(
      id: id,
      title: title,
      content: content,
      folder: folder ?? oldNote.folder,
      isPinned: oldNote.isPinned,
    );
    ref.invalidateSelf();
  }

  Future<void> togglePin(final String id) async {
    final List<Note> currentList = state.value ?? [];
    final Note note = currentList.firstWhere((final n) => n.id == id);

    await rust_api.updateNote(
      id: id,
      title: note.title,
      content: note.content,
      folder: note.folder,
      isPinned: !note.isPinned,
    );
    ref.invalidateSelf();
  }

  Future<void> deleteNote(final String id) async {
    await rust_api.deleteNote(id: id);
    ref.invalidateSelf();
  }

  Future<void> restoreNote(final String id) async {
    await rust_api.restoreNote(id: id);
    ref.invalidateSelf();
  }
}
