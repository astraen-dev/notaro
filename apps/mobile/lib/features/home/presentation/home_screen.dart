import "dart:async";
import "dart:ui";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_screenutil/flutter_screenutil.dart";
import "package:go_router/go_router.dart";
import "package:lucide_icons_flutter/lucide_icons.dart";
import "package:notaro_mobile/features/home/presentation/widgets/note_card.dart";
import "package:notaro_mobile/features/notes/application/notes_provider.dart";
import "package:notaro_mobile/features/notes/domain/note.dart";
import "package:notaro_mobile/features/settings/presentation/settings_modal.dart";
import "package:notaro_mobile/shared/widgets/mesh_gradient_scaffold.dart";

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // 'all', 'pinned', 'trash', or a specific folder name
  String _selectedFilter = "all";
  String _searchQuery = "";
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final List<Note> notes = ref.watch(notesProvider);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // 1. Extract Unique Folders (Logic mirrors Desktop noteStore availableFolders)
    final Set<String> folders = notes
        .where(
          (final n) =>
              !n.isDeleted && n.folder != null && n.folder!.trim().isNotEmpty,
        )
        .map((final n) => n.folder!)
        .toSet();
    final List<String> sortedFolders = folders.toList()..sort();

    // 2. Filter Logic (Logic mirrors Desktop noteStore filteredNotes)
    final List<Note> filteredNotes =
        notes.where((final note) {
            // A. Search Text Filter
            if (_searchQuery.isNotEmpty) {
              final String query = _searchQuery.toLowerCase();
              final bool matches =
                  note.title.toLowerCase().contains(query) ||
                  note.content.toLowerCase().contains(query);
              if (!matches) {
                return false;
              }
            }

            // B. Context Filter
            if (_selectedFilter == "trash") {
              // In trash mode, ONLY show deleted notes
              return note.isDeleted;
            }

            // In normal modes, ONLY show active notes
            if (note.isDeleted) {
              return false;
            }

            if (_selectedFilter == "all") {
              return true;
            }
            if (_selectedFilter == "pinned") {
              return note.isPinned;
            }

            // Folder match
            return note.folder == _selectedFilter;
          }).toList()
          // 3. Sort (Pinned first, then updated date)
          ..sort((final a, final b) {
            if (a.isPinned != b.isPinned) {
              return a.isPinned ? -1 : 1;
            }
            return b.updatedAt.compareTo(a.updatedAt);
          });

    return MeshGradientScaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Prevent creation if in Trash view
          if (_selectedFilter == "trash") {
            return;
          }

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
          // --- Header ---
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
            pinned: false,
            expandedHeight: 100.h,
            backgroundColor: Colors.transparent,
            actions: [
              IconButton(
                icon: Icon(LucideIcons.settings, size: 20.sp),
                onPressed: () {
                  unawaited(
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      barrierColor: Colors.black.withValues(alpha: 0.2),
                      isScrollControlled: true,
                      builder: (final _) => const SettingsModal(),
                    ),
                  );
                },
              ),
              SizedBox(width: 8.w),
            ],
          ),

          // --- Search Bar ---
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B).withValues(
                              alpha: 0.5,
                            ) // Slate-800/50
                          : const Color(0xFFF8FAFC).withValues(alpha: 0.5),
                      // Slate-50/50
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.transparent,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (final val) =>
                          setState(() => _searchQuery = val),
                      style: TextStyle(fontSize: 14.sp),
                      decoration: InputDecoration(
                        hintText: "Search notes...",
                        hintStyle: TextStyle(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                          fontSize: 14.sp,
                        ),
                        prefixIcon: Icon(
                          LucideIcons.search,
                          size: 16.sp,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(LucideIcons.x, size: 14.sp),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = "");
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                        isDense: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // --- Filter Chips (Standard + Folders) ---
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
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

                  // Divider between standard filters and folders
                  if (sortedFolders.isNotEmpty) ...[
                    Container(
                      height: 20.h,
                      width: 1.w,
                      margin: EdgeInsets.symmetric(horizontal: 12.w),
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.2,
                      ),
                    ),
                    // Dynamic Folders
                    ...sortedFolders.map(
                      (final folder) => Padding(
                        padding: EdgeInsets.only(right: 8.w),
                        child: _FilterChip(
                          label: folder,
                          icon: LucideIcons.folder,
                          isSelected: _selectedFilter == folder,
                          onTap: () => setState(() => _selectedFilter = folder),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // --- Notes List ---
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
                      _searchQuery.isNotEmpty
                          ? "No matches found"
                          : "No notes here",
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
              padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 100.h),
              sliver: SliverList.builder(
                itemCount: filteredNotes.length,
                itemBuilder: (final context, final index) {
                  final Note note = filteredNotes[index];

                  return Dismissible(
                    key: Key(note.id),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (final direction) async {
                      if (_selectedFilter == "trash") {
                        // TODO: Implement Restore/Hard Delete for Trash view
                        return false;
                      }
                      ref.read(notesProvider.notifier).deleteNote(note.id);
                      return false; // We let the provider update state to remove it
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Style matches desktop Sidebar "Filter Tabs" & "Folder Pills"
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? colorScheme.primary.withValues(alpha: 0.2)
                    : colorScheme.primary.withValues(alpha: 0.1))
              : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.2)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14.sp,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: 6.w),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
