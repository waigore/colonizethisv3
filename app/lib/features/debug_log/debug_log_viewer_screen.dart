// Debug log viewer. SPEC/program/debug-log-viewer.md.

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:session_log_buffer/session_log_buffer.dart';
import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/ui_screen_ids.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';

/// Full-screen viewer for session logs with multiselect filters by package and level.
class DebugLogViewerScreen extends StatefulWidget {
  const DebugLogViewerScreen({super.key});

  static const screenId = UiScreenIds.debugLogViewer;

  @override
  State<DebugLogViewerScreen> createState() => _DebugLogViewerScreenState();
}

class _DebugLogViewerScreenState extends State<DebugLogViewerScreen> {
  /// Package chips in the app viewer; omits `ctdev` per SPEC/program/debug-log-viewer.md.
  static final List<String> _viewerPackagePrefixes = List<String>.unmodifiable(
    knownPrefixes.where((String p) => p != 'ctdev').toList(),
  );

  static final Set<Level> _defaultLevels = <Level>{
    Level.info,
    Level.warning,
    Level.error,
  };

  Set<String> _selectedPrefixes = {'app'};
  Set<Level> _selectedLevels = Set<Level>.from(_defaultLevels);

  List<SessionLogEntry> get _filtered =>
      SessionLogBuffer.instance.getFiltered(
        selectedPrefixes: _selectedPrefixes,
        selectedLevels: _selectedLevels,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.debugLog_title),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: l10n.common_close,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFilters(context),
          const Divider(height: 1),
          Expanded(child: _buildLogList(context)),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = appL10n(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(CtSpacing.m),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.debugLog_filter_package, style: theme.textTheme.titleSmall),
          const SizedBox(width: CtSpacing.m),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: _viewerPackagePrefixes.map((p) {
              final selected = _selectedPrefixes.contains(p);
              return FilterChip(
                label: Text(p),
                selected: selected,
                onSelected: (_) {
                  setState(() {
                    if (selected) {
                      _selectedPrefixes = Set.from(_selectedPrefixes)..remove(p);
                    } else {
                      _selectedPrefixes = Set.from(_selectedPrefixes)..add(p);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(width: CtSpacing.l),
          Text(l10n.debugLog_filter_level, style: theme.textTheme.titleSmall),
          const SizedBox(width: CtSpacing.m),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: knownLevels.map((l) {
              final selected = _selectedLevels.contains(l);
              return FilterChip(
                label: Text(l.name),
                selected: selected,
                onSelected: (_) {
                  setState(() {
                    if (selected) {
                      _selectedLevels = Set.from(_selectedLevels)..remove(l);
                    } else {
                      _selectedLevels = Set.from(_selectedLevels)..add(l);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLogList(BuildContext context) {
    final entries = _filtered;
    final theme = Theme.of(context);
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final lines = entry.displayLines;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: lines.map((line) {
            final isFirst = line == lines.first;
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: CtSpacing.ml,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: isFirst ? _levelColor(entry.level).withValues(alpha: 0.08) : null,
              ),
              child: SelectableText(
                line,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  /// Row-tint colour per log level, resolved through canonical
  /// [EditorialMonoclePalette] tokens. The viewer applies the returned colour
  /// with an `0.08` alpha to the first line of each entry as a subtle
  /// background wash; the four-tier warm gradient (`danger` → `accent` →
  /// `accentDim` → `muted`) signals severity within the editorial-monocle
  /// dark theme without resorting to Material's blue/orange tones, which
  /// the theme does not define.
  ///
  /// SPEC: `SPEC/program/debug-log-viewer.md` § Visual chrome, palette tokens
  /// per `SPEC/ui/pixel-art-ui-catalog.md` § Editorial-monocle palette.
  /// Refs #2914 S3 (token adoption / G1 allowlist promotion).
  Color _levelColor(Level level) {
    switch (level) {
      case Level.error:
        return EditorialMonoclePalette.danger;
      case Level.warning:
        return EditorialMonoclePalette.accent;
      case Level.info:
        return EditorialMonoclePalette.accentDim;
      default:
        return EditorialMonoclePalette.muted;
    }
  }
}
