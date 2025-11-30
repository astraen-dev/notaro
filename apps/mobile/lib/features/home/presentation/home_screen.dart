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
import "package:notaro_mobile/shared/widgets/mesh_gradient_scaffold.dart";

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedFilter = "all";

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

    return MeshGradientScaffold(
      // Custom Glassy FAB
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.read(notesProvider.notifier).addNote();
          final String newId = ref.read(notesProvider).first.id;
          unawaited(context.pushNamed("editor", pathParameters: {"id": newId}));
        },
        backgroundColor: colorScheme.surface.withValues(alpha: 0.8),
        foregroundColor: colorScheme.primary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.1)),
        ),
        child: Icon(LucideIcons.plus, size: 24.sp),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Clean Minimal Header (Desktop Sidebar Header Style)
          SliverAppBar.large(
            title: Row(
              children: [
                Icon(
                  LucideIcons.cloud,
                  size: 24.sp,
                  color: colorScheme.primary.withValues(alpha: 0.8),
                ),
                SizedBox(width: 8.w),
                Text(
                  "Notaro",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.sp,
                    color: colorScheme.onSurface.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
            centerTitle: false,
            floating: true,
            expandedHeight: 100.h,
            backgroundColor: Colors.transparent,
            // Let mesh show through
            actions: [
              IconButton(
                icon: Icon(
                  themeMode == ThemeMode.dark
                      ? LucideIcons.sun
                      : LucideIcons.moon,
                  size: 20.sp,
                ),
                onPressed: () =>
                    ref.read(themeModeProvider.notifier).toggleTheme(),
              ),
              IconButton(
                icon: Icon(LucideIcons.settings, size: 20.sp),
                onPressed: () {},
              ),
              SizedBox(width: 8.w),
            ],
          ),

          // Filter Chips (Pill Style)
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                children: [
                  _FilterChip(
                    label: "All",
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
                      size: 48.sp,
                      color: colorScheme.onSurface.withValues(alpha: 0.2),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      "No notes",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
              sliver: SliverList.builder(
                itemCount: filteredNotes.length,
                itemBuilder: (final context, final index) {
                  final Note note = filteredNotes[index];

                  return Dismissible(
                    key: Key(note.id),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (final direction) async {
                      if (_selectedFilter == "trash") {
                        return false;
                      }
                      ref.read(notesProvider.notifier).deleteNote(note.id);
                      return false;
                    },
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(right: 20.w),
                      child: Icon(
                        LucideIcons.trash2,
                        color: Colors.red,
                        size: 20.sp,
                      ),
                    ),
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
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    // Style matches desktop Sidebar "Filter Tabs"
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14.sp,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: 4.w),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
