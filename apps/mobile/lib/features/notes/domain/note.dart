import "package:freezed_annotation/freezed_annotation.dart";

part "note.freezed.dart";
part "note.g.dart";

@freezed
abstract class Note with _$Note {
  const factory Note({
    required final String id,
    required final String title,
    required final String content,
    @JsonKey(name: "updated_at") required final DateTime updatedAt,
    required final int version,
    final String? folder,
    @JsonKey(name: "is_pinned") @Default(false) final bool isPinned,
    @JsonKey(name: "is_deleted") @Default(false) final bool isDeleted,
  }) = _Note;

  factory Note.fromJson(final Map<String, dynamic> json) =>
      _$NoteFromJson(json);
}
