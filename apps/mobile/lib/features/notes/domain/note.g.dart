// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Note _$NoteFromJson(Map<String, dynamic> json) => _Note(
  id: json['id'] as String,
  title: json['title'] as String,
  content: json['content'] as String,
  updatedAt: DateTime.parse(json['updated_at'] as String),
  version: (json['version'] as num).toInt(),
  folder: json['folder'] as String?,
  isPinned: json['is_pinned'] as bool? ?? false,
  isDeleted: json['is_deleted'] as bool? ?? false,
);

Map<String, dynamic> _$NoteToJson(_Note instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'content': instance.content,
  'updated_at': instance.updatedAt.toIso8601String(),
  'version': instance.version,
  'folder': instance.folder,
  'is_pinned': instance.isPinned,
  'is_deleted': instance.isDeleted,
};
