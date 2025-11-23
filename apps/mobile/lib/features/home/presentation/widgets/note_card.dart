import "package:flutter/material.dart";
import "package:flutter_screenutil/flutter_screenutil.dart";
import "package:intl/intl.dart";
import "package:lucide_icons_flutter/lucide_icons.dart";
import "package:notaro_mobile/features/notes/domain/note.dart";

class NoteCard extends StatelessWidget {
  const NoteCard({required this.note, required this.onTap, super.key});

  final Note note;
  final VoidCallback onTap;

  String _formatDate(final DateTime date) {
    final now = DateTime.now();
    final Duration diff = now.difference(date);
    if (diff.inDays < 1) {
      return DateFormat.jm().format(date);
    } else if (diff.inDays < 7) {
      return DateFormat.E().format(date);
    }
    return DateFormat.MMMd().format(date);
  }

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        // Faux Glassmorphism: Gradient + Border instead of expensive blur
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF2C3238).withValues(alpha: 0.8),
                  const Color(0xFF1C2226).withValues(alpha: 0.6),
                ]
              : [
                  Colors.white.withValues(alpha: 0.9),
                  Colors.white.withValues(alpha: 0.5),
                ],
        ),
        border: Border.all(
          color: note.isPinned
              ? colorScheme.primary.withValues(alpha: 0.3)
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20.r),
          child: Padding(
            padding: EdgeInsets.all(18.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        note.title.isEmpty ? "Untitled Note" : note.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 17.sp,
                          color: note.title.isEmpty
                              ? colorScheme.onSurface.withValues(alpha: 0.5)
                              : colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (note.isPinned)
                      Padding(
                        padding: EdgeInsets.only(left: 8.w),
                        child: Transform.rotate(
                          angle: 0.5,
                          child: Icon(
                            LucideIcons.pin,
                            size: 14.sp,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 8.h),
                if (note.content.isNotEmpty)
                  Text(
                    note.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                      fontSize: 14.sp,
                    ),
                  ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Text(
                      _formatDate(note.updatedAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.7,
                        ),
                        fontSize: 11.sp,
                      ),
                    ),
                    const Spacer(),
                    if (note.folder != null) ...[
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.folder,
                              size: 10.sp,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              note.folder!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
