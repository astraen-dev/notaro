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

  @override
  void initState() {
    super.initState();
    final Note note = ref
        .read(notesProvider)
        .firstWhere(
          (final n) => n.id == widget.noteId,
          orElse: () => throw Exception("Note not found"),
        );
    _titleController = TextEditingController(text: note.title);
    _contentController = TextEditingController(text: note.content);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _save() {
    ref
        .read(notesProvider.notifier)
        .updateNote(
          widget.noteId,
          _titleController.text,
          _contentController.text,
        );
  }

  @override
  Widget build(final BuildContext context) {
    final Note note = ref
        .watch(notesProvider)
        .firstWhere(
          (final n) => n.id == widget.noteId,
          orElse: () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.pop();
              }
            });
            return ref.read(notesProvider).first;
          },
        );

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Use MeshGradientScaffold for background consistency
    return MeshGradientScaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 1. Toolbar (Matches Desktop Header)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
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
                  IconButton(
                    icon: Icon(
                      note.isPinned ? LucideIcons.pin : LucideIcons.pinOff,
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
                    onPressed: () =>
                        ref.read(notesProvider.notifier).togglePin(note.id),
                  ),
                  SizedBox(width: 8.w),
                  IconButton(
                    icon: Icon(LucideIcons.trash2, size: 20.sp),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(
                        alpha: isDark ? 0.1 : 0.5,
                      ),
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: () {
                      ref.read(notesProvider.notifier).deleteNote(note.id);
                      context.pop();
                    },
                  ),
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
                        children: [
                          // Title Input
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              24.w,
                              32.h,
                              24.w,
                              16.h,
                            ),
                            child: TextField(
                              controller: _titleController,
                              onChanged: (_) => _save(),
                              style: TextStyle(
                                fontSize: 28.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                                height: 1.2,
                              ),
                              decoration: InputDecoration(
                                hintText: S.of(context).noteUntitled,
                                hintStyle: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface
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
                              style: TextStyle(
                                fontSize: 16.sp,
                                height: 1.6,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.9),
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

                          // Info Footer
                          Padding(
                            padding: EdgeInsets.all(16.w),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  S
                                      .of(context)
                                      .editorCharCount(
                                        _contentController.text.length,
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
  }
}
