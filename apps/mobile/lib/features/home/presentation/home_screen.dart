import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:lucide_icons_flutter/lucide_icons.dart";
import "package:notaro_mobile/core/ui/theme_provider.dart";
import "package:notaro_mobile/features/home/presentation/widgets/note_card.dart";
import "package:notaro_mobile/features/notes/application/notes_provider.dart";
import "package:notaro_mobile/features/notes/domain/note.dart";

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedFilter = "all"; // all, pinned, trash

  @override
  Widget build(final BuildContext context) {
    final List<Note> notes = ref.watch(notesProvider);
    final ThemeMode themeMode = ref.watch(themeModeProvider);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    // Filter Logic
    final List<Note> filteredNotes = notes.where((final note) {
      if (_selectedFilter == "trash") {
        return note.isDeleted;
      }
      if (note.isDeleted) {
        return false;
      }
      if (_selectedFilter == "pinned") {
        return note.isPinned;
      }
      return true;
    }).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Native Mobile Header
          SliverAppBar.large(
            title: const Text("Notaro"),
            centerTitle: false,
            actions: [
              IconButton(
                icon: Icon(
                  themeMode == ThemeMode.dark
                      ? LucideIcons.sun
                      : LucideIcons.moon,
                ),
                onPressed: () =>
                    ref.read(themeModeProvider.notifier).toggleTheme(),
              ),
              IconButton(
                icon: const Icon(LucideIcons.settings),
                onPressed: () {}, // Todo: Settings Route
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Filter Chips
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _FilterChip(
                    label: "All Notes",
                    icon: LucideIcons.layers,
                    isSelected: _selectedFilter == "all",
                    onTap: () => setState(() => _selectedFilter = "all"),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: "Pinned",
                    icon: LucideIcons.pin,
                    isSelected: _selectedFilter == "pinned",
                    onTap: () => setState(() => _selectedFilter = "pinned"),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: "Trash",
                    icon: LucideIcons.trash2,
                    isSelected: _selectedFilter == "trash",
                    onTap: () => setState(() => _selectedFilter = "trash"),
                  ),
                ],
              ),
            ),
          ),

          // Notes List
          if (filteredNotes.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.fileText,
                      size: 48,
                      color: colorScheme.outline.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No notes found",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList.builder(
                itemCount: filteredNotes.length,
                itemBuilder: (final context, final index) {
                  final Note note = filteredNotes[index];

                  // Swipe to Delete/Restore
                  return Dismissible(
                    key: Key(note.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: colorScheme.errorContainer,
                      child: Icon(
                        LucideIcons.trash2,
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                    confirmDismiss: (final direction) async {
                      if (_selectedFilter == "trash") {
                        // Permanently delete logic would go here
                        return false;
                      }
                      ref.read(notesProvider.notifier).deleteNote(note.id);
                      return false; // Don't remove from UI immediately, let provider update state
                    },
                    child: NoteCard(
                      note: note,
                      onTap: () {
                        unawaited(
                          context.pushNamed(
                            "editor",
                            pathParameters: {"id": note.id},
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref.read(notesProvider.notifier).addNote();
          // Get the newly created note (first in list) and navigate
          final String newId = ref.read(notesProvider).first.id;
          unawaited(context.pushNamed("editor", pathParameters: {"id": newId}));
        },
        icon: const Icon(LucideIcons.plus),
        label: const Text("New Note"),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.transparent : colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
