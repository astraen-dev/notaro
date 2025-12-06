import "dart:async";
import "dart:ui";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_screenutil/flutter_screenutil.dart";
import "package:go_router/go_router.dart";
import "package:lucide_icons_flutter/lucide_icons.dart";
import "package:notaro_mobile/features/notes/application/notes_provider.dart";
import "package:notaro_mobile/features/notes/domain/note.dart";
import "package:notaro_mobile/generated/l10n.dart";
import "package:notaro_mobile/shared/widgets/mesh_gradient_scaffold.dart";

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({required this.noteId, super.key});

  final String noteId;

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  // Track if we have populated the controllers with the initial data
  bool _isInitialized = false;
  String? _currentFolder;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _save() {
    unawaited(
      ref
          .read(notesProvider.notifier)
          .updateNote(
            widget.noteId,
            _titleController.text,
            _contentController.text,
            folder: _currentFolder,
          ),
    );
  }

  Future<void> _showFolderDialog(
    final BuildContext context,
    final List<Note> allNotes,
  ) async {
    final Set<String> folders = allNotes
        .where(
          (final n) =>
              !n.isDeleted && n.folder != null && n.folder!.trim().isNotEmpty,
        )
        .map((final n) => n.folder!)
        .toSet();

    final TextEditingController folderController = TextEditingController(
      text: _currentFolder,
    );

    await showDialog(
      context: context,
      builder: (final context) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          title: Text(S.of(context).folderAssignTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: folderController,
                decoration: InputDecoration(
                  hintText: S.of(context).folderNewName,
                  filled: true,
                  fillColor: isDark
                      ? Colors.black.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (folders.isNotEmpty) ...[
                SizedBox(height: 16.h),
                Text(
                  S.of(context).folderExisting,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: folders
                      .map(
                        (final f) => ActionChip(
                          label: Text(f),
                          onPressed: () {
                            folderController.text = f;
                          },
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(S.of(context).cancel),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  _currentFolder = folderController.text.trim().isEmpty
                      ? null
                      : folderController.text.trim();
                });
                _save();
                Navigator.pop(context);
              },
              child: Text(S.of(context).save),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(final BuildContext context) {
    final AsyncValue<List<Note>> notesAsync = ref.watch(notesProvider);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return notesAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (final err, _) =>
          Scaffold(body: Center(child: Text("Error: $err"))),
      data: (final notes) {
        // Find the specific note
        final Note note = notes.firstWhere(
          (final n) => n.id == widget.noteId,
          orElse: () {
            // Note might have been deleted or doesn't exist.
            // Schedule a pop to avoid stuck UI.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.pop();
              }
            });
            // Return a dummy note to satisfy the build method temporarily
            return Note(
              id: "",
              title: "",
              content: "",
              updatedAt: DateTime.now(),
              version: 0,
            );
          },
        );

        // If the note wasn't found (dummy note returned), don't build the UI
        if (note.id.isEmpty) {
          return const SizedBox.shrink();
        }

        // Initialize controllers ONCE
        if (!_isInitialized) {
          _titleController.text = note.title;
          _contentController.text = note.content;
          _currentFolder = note.folder;
          _isInitialized = true;
        }

        return MeshGradientScaffold(
          body: SafeArea(
            child: Column(
              children: [
                // 0. Trash Banner
                if (note.isDeleted)
                  Container(
                    width: double.infinity,
                    color: Theme.of(
                      context,
                    ).colorScheme.error.withValues(alpha: 0.1),
                    padding: EdgeInsets.symmetric(
                      vertical: 8.h,
                      horizontal: 16.w,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.trash2,
                          size: 16.sp,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          S.of(context).noteInTrashWarning,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                // 1. Toolbar
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(LucideIcons.chevronLeft, size: 24.sp),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(
                            alpha: isDark ? 0.1 : 0.5,
                          ),
                        ),
                        onPressed: context.pop,
                      ),
                      const Spacer(),
                      // Actions based on state
                      if (!note.isDeleted) ...[
                        // Pin
                        IconButton(
                          icon: Icon(
                            note.isPinned
                                ? LucideIcons.pin
                                : LucideIcons.pinOff,
                            size: 20.sp,
                            color: note.isPinned
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: isDark ? 0.1 : 0.5,
                            ),
                          ),
                          onPressed: () => ref
                              .read(notesProvider.notifier)
                              .togglePin(note.id),
                        ),
                        SizedBox(width: 8.w),
                        // Folder
                        IconButton(
                          icon: Icon(
                            _currentFolder != null
                                ? LucideIcons.folderOpen
                                : LucideIcons.folder,
                            size: 20.sp,
                            color: _currentFolder != null
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: isDark ? 0.1 : 0.5,
                            ),
                          ),
                          onPressed: () => _showFolderDialog(context, notes),
                        ),
                        SizedBox(width: 8.w),
                        // Soft Delete
                        IconButton(
                          icon: Icon(LucideIcons.trash2, size: 20.sp),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: isDark ? 0.1 : 0.5,
                            ),
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.error,
                          ),
                          onPressed: () {
                            unawaited(
                              ref
                                  .read(notesProvider.notifier)
                                  .deleteNote(note.id),
                            );
                            context.pop();
                          },
                        ),
                      ] else ...[
                        // Restore
                        IconButton(
                          tooltip: S.of(context).restoreNote,
                          icon: Icon(LucideIcons.rotateCcw, size: 20.sp),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: isDark ? 0.1 : 0.5,
                            ),
                            foregroundColor: Colors.green,
                          ),
                          onPressed: () {
                            unawaited(
                              ref
                                  .read(notesProvider.notifier)
                                  .restoreNote(note.id),
                            );
                            // Stay on screen, it will refresh to active state
                          },
                        ),
                        SizedBox(width: 8.w),
                        // Hard Delete
                        IconButton(
                          tooltip: S.of(context).deletePermanently,
                          icon: Icon(LucideIcons.trash2, size: 20.sp),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: isDark ? 0.1 : 0.5,
                            ),
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.error,
                          ),
                          onPressed: () {
                            unawaited(
                              ref
                                  .read(notesProvider.notifier)
                                  .deleteNote(note.id),
                            );
                            context.pop();
                          },
                        ),
                      ],
                    ],
                  ),
                ),

                // 2. Editor Pane (Glass Card)
                Expanded(
                  child: Container(
                    margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24.r),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.6),
                            border: Border.all(
                              color: Colors.white.withValues(
                                alpha: isDark ? 0.1 : 0.4,
                              ),
                            ),
                            borderRadius: BorderRadius.circular(24.r),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Folder Indicator (if set)
                              if (_currentFolder != null && !note.isDeleted)
                                Padding(
                                  padding: EdgeInsets.only(
                                    left: 24.w,
                                    top: 24.h,
                                    right: 24.w,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        LucideIcons.folder,
                                        size: 12.sp,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.7),
                                      ),
                                      SizedBox(width: 6.w),
                                      Text(
                                        _currentFolder!,
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Title Input
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  24.w,
                                  _currentFolder != null ? 12.h : 32.h,
                                  24.w,
                                  16.h,
                                ),
                                child: TextField(
                                  controller: _titleController,
                                  onChanged: (_) => _save(),
                                  enabled:
                                      !note.isDeleted, // Disable if deleted
                                  style: TextStyle(
                                    fontSize: 28.sp,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                    height: 1.2,
                                    color: note.isDeleted
                                        ? Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.5)
                                        : null,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: S.of(context).noteUntitled,
                                    hintStyle: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.3),
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  maxLines: null,
                                  textInputAction: TextInputAction.next,
                                ),
                              ),

                              // Content Input
                              Expanded(
                                child: TextField(
                                  controller: _contentController,
                                  onChanged: (_) => _save(),
                                  enabled:
                                      !note.isDeleted, // Disable if deleted
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    height: 1.6,
                                    color: note.isDeleted
                                        ? Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.5)
                                        : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.9),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: S.of(context).editorStartTyping,
                                    hintStyle: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant
                                          .withValues(alpha: 0.4),
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 24.w,
                                    ),
                                  ),
                                  maxLines: null,
                                  expands: true,
                                  textAlignVertical: TextAlignVertical.top,
                                ),
                              ),

                              // Info Footer (Words, Chars, Version)
                              Padding(
                                padding: EdgeInsets.all(16.w),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ValueListenableBuilder(
                                      valueListenable: _contentController,
                                      builder:
                                          (
                                            final context,
                                            final value,
                                            final child,
                                          ) {
                                            final String text = value.text;
                                            final int wordCount =
                                                text.trim().isEmpty
                                                ? 0
                                                : text
                                                      .trim()
                                                      .split(RegExp(r"\s+"))
                                                      .length;

                                            return Text(
                                              S
                                                  .of(context)
                                                  .editorStats(
                                                    wordCount,
                                                    text.length,
                                                    note.version,
                                                  ),
                                              style: TextStyle(
                                                fontSize: 10.sp,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.4),
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.5,
                                              ),
                                            );
                                          },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
