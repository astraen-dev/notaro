import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_screenutil/flutter_screenutil.dart";
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
      extendBody: true,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Glassy Sliver App Bar
          SliverAppBar.large(
            title: Text(
              "Notaro",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: -1.sp,
              ),
            ),
            centerTitle: false,
            floating: true,
            expandedHeight: 120.h,
            backgroundColor: colorScheme.surface.withValues(alpha: 0.9),
            surfaceTintColor: Colors.transparent,
            actions: [
              IconButton(
                icon: Icon(
                  themeMode == ThemeMode.dark
                      ? LucideIcons.sun
                      : LucideIcons.moon,
                  size: 22.sp,
                ),
                onPressed: () =>
                    ref.read(themeModeProvider.notifier).toggleTheme(),
              ),
              Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: IconButton(
                  icon: Icon(LucideIcons.settings, size: 22.sp),
                  onPressed: () {},
                ),
              ),
            ],
          ),

          // Filter Chips
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Row(
                children: [
                  _FilterChip(
                    label: "All Notes",
                    icon: LucideIcons.layers,
                    isSelected: _selectedFilter == "all",
                    onTap: () => setState(() => _selectedFilter = "all"),
                  ),
                  SizedBox(width: 8.w),
                  _FilterChip(
                    label: "Pinned",
                    icon: LucideIcons.pin,
                    isSelected: _selectedFilter == "pinned",
                    onTap: () => setState(() => _selectedFilter = "pinned"),
                  ),
                  SizedBox(width: 8.w),
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
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.fileText,
                      size: 64.sp,
                      color: colorScheme.outline.withValues(alpha: 0.3),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      "No notes found",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 16.sp,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 100.h),
              sliver: SliverList.builder(
                itemCount: filteredNotes.length,
                itemBuilder: (final context, final index) {
                  final Note note = filteredNotes[index];

                  return Dismissible(
                    key: Key(note.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      margin: EdgeInsets.only(bottom: 12.h),
                      alignment: Alignment.centerRight,
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      padding: EdgeInsets.only(right: 24.w),
                      child: Icon(
                        LucideIcons.trash2,
                        color: colorScheme.onErrorContainer,
                        size: 24.sp,
                      ),
                    ),
                    confirmDismiss: (final direction) async {
                      if (_selectedFilter == "trash") {
                        return false;
                      }
                      ref.read(notesProvider.notifier).deleteNote(note.id);
                      return false;
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
          final String newId = ref.read(notesProvider).first.id;
          unawaited(context.pushNamed("editor", pathParameters: {"id": newId}));
        },
        backgroundColor: colorScheme.primary,
        elevation: 4,
        highlightElevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.r),
        ),
        icon: Icon(LucideIcons.plus, color: colorScheme.onPrimary, size: 24.sp),
        label: Text(
          "New Note",
          style: TextStyle(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 14.sp,
          ),
        ),
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
      borderRadius: BorderRadius.circular(24.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.transparent : colorScheme.outlineVariant,
            width: 1.w,
          ),
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16.sp,
              color: isSelected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
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
