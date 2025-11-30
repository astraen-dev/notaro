import "dart:async";

import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter_screenutil/flutter_screenutil.dart";
import "package:go_router/go_router.dart";
import "package:lucide_icons_flutter/lucide_icons.dart";
import "package:notaro_mobile/generated/l10n.dart";
import "package:notaro_mobile/oss_licenses.dart" as oss;
import "package:notaro_mobile/shared/widgets/mesh_gradient_scaffold.dart";

class LicensesScreen extends StatefulWidget {
  const LicensesScreen({super.key});

  @override
  State<LicensesScreen> createState() => _LicensesScreenState();
}

class _LicensesScreenState extends State<LicensesScreen> {
  @override
  Widget build(final BuildContext context) {
    final S l10n = S.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    // Sort packages alphabetically
    final List<oss.Package> packages = [...oss.allDependencies]
      ..sort(
        (final a, final b) =>
            a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

    // Group packages by the first letter of their name
    final Map<String, List<oss.Package>> grouped = groupBy<oss.Package, String>(
      packages,
      (final p) => p.name[0].toUpperCase(),
    );

    // Create a flat list with headers (String) and items (Package)
    final List<dynamic> items = [];
    final List<String> sortedKeys = grouped.keys.toList()..sort();
    for (final String key in sortedKeys) {
      items
        ..add(key)
        ..addAll(grouped[key]!);
    }

    return MeshGradientScaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(
              l10n.settingsLicenses,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            centerTitle: false,
            leading: IconButton(
              icon: Icon(LucideIcons.chevronLeft, size: 24.sp),
              onPressed: context.pop,
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 32.h),
            sliver: SliverList.builder(
              itemCount: items.length,
              itemBuilder: (final context, final index) {
                final dynamic item = items[index];
                Widget child;

                if (item is String) {
                  child = _LicenseGroupHeader(letter: item);
                } else if (item is oss.Package) {
                  final bool isLastOfGroup =
                      (index + 1 == items.length) ||
                      (items[index + 1] is String);

                  child = Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    margin: EdgeInsets.only(bottom: 8.h),
                    child: _LicenseListItem(
                      package: item,
                      isLastOfGroup: isLastOfGroup,
                    ),
                  );
                } else {
                  child = const SizedBox.shrink();
                }

                return child;
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LicenseGroupHeader extends StatelessWidget {
  const _LicenseGroupHeader({required this.letter});

  final String letter;

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(8.w, 24.h, 8.w, 12.h),
      child: Text(
        letter,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 16.sp,
        ),
      ),
    );
  }
}

class _LicenseListItem extends StatelessWidget {
  const _LicenseListItem({required this.package, required this.isLastOfGroup});

  final oss.Package package;
  final bool isLastOfGroup;

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final S l10n = S.of(context);

    return ListTile(
      title: Text(
        package.name,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 14.sp,
        ),
      ),
      subtitle: Text(
        l10n.licensePackageVersion(package.version ?? "N/A"),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 12.sp,
        ),
      ),
      trailing: Icon(
        LucideIcons.chevronRight,
        size: 16.sp,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
      onTap: () {
        unawaited(
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (final _) => _LicenseDetailScreen(package: package),
            ),
          ),
        );
      },
    );
  }
}

class _LicenseDetailScreen extends StatelessWidget {
  const _LicenseDetailScreen({required this.package});

  final oss.Package package;

  /// This reformats license text to improve readability by intelligently
  /// handling line breaks.
  String _reflowLicenseText(final String text) {
    final List<String> lines = text.split("\n");
    final buffer = StringBuffer();

    for (int i = 0; i < lines.length; i++) {
      final String currentLine = lines[i].trim();
      buffer.write(currentLine);

      if (i == lines.length - 1) {
        break;
      }

      final String nextLine = lines[i + 1];
      final String nextLineTrimmed = nextLine.trim();

      // Determine if the current line break is structural ("hard")
      final bool isParagraphBreak =
          (currentLine.isEmpty && nextLineTrimmed.isNotEmpty) ||
          (nextLineTrimmed.isEmpty && currentLine.isNotEmpty);
      final bool isListItem = nextLineTrimmed.startsWith(
        RegExp(r"\*|•|- |[0-9]+\.|\([a-zA-Z0-9]+\)"),
      );
      final bool endsWithColon = currentLine.endsWith(":");
      final bool isDivider = RegExp(r"^(=+|-+|\*+|_+)$").hasMatch(currentLine);

      if (isParagraphBreak || isListItem || endsWithColon || isDivider) {
        // This is a structural break, so preserve the newline.
        buffer.write("\n");
      } else if (currentLine.isNotEmpty) {
        // This is a soft break (part of a flowing paragraph).
        buffer.write(" ");
      }
    }
    return buffer.toString();
  }

  void _showDisclaimer(final BuildContext context) {
    final S l10n = S.of(context);
    unawaited(
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (final context) {
          final bool isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            ),
            padding: EdgeInsets.all(24.w),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.licenseDisclaimerTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    l10n.licenseDisclaimerContent,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  SizedBox(height: 24.h),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.okButtonLabel),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String licenseText = package.license ?? "License text not available.";
    final S l10n = S.of(context);

    return MeshGradientScaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(LucideIcons.chevronLeft, size: 24.sp),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      package.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.info, size: 24.sp),
                    tooltip: l10n.licenseDisclaimerTitle,
                    onPressed: () => _showDisclaimer(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24.w),
                  child: SelectableText(
                    _reflowLicenseText(licenseText),
                    style: theme.textTheme.bodyMedium!.copyWith(
                      fontFamily: "monospace",
                      height: 1.5,
                      fontSize: 12.sp,
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
