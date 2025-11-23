import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_screenutil/flutter_screenutil.dart";
import "package:go_router/go_router.dart";
import "package:lucide_icons_flutter/lucide_icons.dart";
import "package:notaro_mobile/features/notes/application/notes_provider.dart";
import "package:notaro_mobile/features/notes/domain/note.dart";

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

    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        leadingWidth: 60.w,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, size: 28.sp),
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.3,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          padding: EdgeInsets.zero,
          onPressed: context.pop,
        ),
        actions: [
          IconButton(
            icon: Icon(
              note.isPinned ? LucideIcons.pin : LucideIcons.pinOff,
              color: note.isPinned
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              size: 22.sp,
            ),
            onPressed: () {
              ref.read(notesProvider.notifier).togglePin(note.id);
            },
          ),
          IconButton(
            icon: Icon(LucideIcons.ellipsisVertical, size: 22.sp),
            onPressed: () async {
              await _showOptionsSheet(context, note);
            },
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              child: TextField(
                controller: _titleController,
                onChanged: (_) => _save(),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                  fontSize: 28.sp,
                  height: 1.2,
                ),
                decoration: InputDecoration(
                  hintText: "Title",
                  hintStyle: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  filled: false,
                ),
                maxLines: null,
                textInputAction: TextInputAction.next,
              ),
            ),
            Expanded(
              child: TextField(
                controller: _contentController,
                onChanged: (_) => _save(),
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                  color: colorScheme.onSurface,
                  fontSize: 16.sp,
                ),
                decoration: InputDecoration(
                  hintText: "Start typing...",
                  hintStyle: TextStyle(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(horizontal: 24.w),
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
            _buildMobileToolbar(context, note),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileToolbar(final BuildContext context, final Note note) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer.withValues(alpha: 0.8),
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            "${_contentController.text.length} chars",
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12.sp,
            ),
          ),
          const Spacer(),
          if (note.folder != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                note.folder!,
                style: theme.textTheme.labelSmall?.copyWith(fontSize: 11.sp),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showOptionsSheet(final BuildContext context, final Note note) =>
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (final ctx) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          padding: EdgeInsets.all(24.w),
          child: SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: Icon(
                    LucideIcons.trash2,
                    color: Colors.red,
                    size: 24.sp,
                  ),
                  title: Text(
                    "Move to Trash",
                    style: TextStyle(color: Colors.red, fontSize: 16.sp),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    ref.read(notesProvider.notifier).deleteNote(note.id);
                    context.pop();
                  },
                ),
                ListTile(
                  leading: Icon(LucideIcons.info, size: 24.sp),
                  title: Text("Details", style: TextStyle(fontSize: 16.sp)),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );
}
