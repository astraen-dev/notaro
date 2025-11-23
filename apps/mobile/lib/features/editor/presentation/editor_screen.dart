import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
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
    // Initialize controllers with current data
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
    // Listen to the specific note to update UI on external changes (e.g. Pin status)
    final Note note = ref
        .watch(notesProvider)
        .firstWhere(
          (final n) => n.id == widget.noteId,
          orElse: () {
            // Note might have been deleted, pop safely
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.pop();
              }
            });
            // Return a dummy to prevent crash before pop
            return ref.read(notesProvider).first;
          },
        );

    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: context.pop,
        ),
        actions: [
          IconButton(
            icon: Icon(
              note.isPinned ? LucideIcons.pin : LucideIcons.pinOff,
              color: note.isPinned ? colorScheme.primary : null,
            ),
            onPressed: () {
              ref.read(notesProvider.notifier).togglePin(note.id);
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.ellipsisVertical),
            onPressed: () async {
              // Show bottom sheet or menu for Delete/Info
              await showModalBottomSheet(
                context: context,
                builder: (final ctx) => SafeArea(
                  child: Wrap(
                    children: [
                      ListTile(
                        leading: const Icon(
                          LucideIcons.trash2,
                          color: Colors.red,
                        ),
                        title: const Text(
                          "Move to Trash",
                          style: TextStyle(color: Colors.red),
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          ref.read(notesProvider.notifier).deleteNote(note.id);
                          context.pop(); // Exit editor
                        },
                      ),
                      ListTile(
                        leading: const Icon(LucideIcons.info),
                        title: const Text("Details"),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: TextField(
              controller: _titleController,
              onChanged: (_) => _save(),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              decoration: const InputDecoration(
                hintText: "Title",
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _contentController,
                onChanged: (_) => _save(),
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                  color: colorScheme.onSurface,
                ),
                decoration: const InputDecoration(
                  hintText: "Start typing...",
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  filled: false,
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
          ),
          // Mobile Toolbar (Word count, basic stats)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                Text(
                  "${_contentController.text.length} chars",
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (note.folder != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      note.folder!,
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
