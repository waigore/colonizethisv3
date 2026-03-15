// Debug log viewer. SPEC/program/debug-log-viewer.md.

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:session_log_buffer/session_log_buffer.dart';

/// Full-screen viewer for session logs with multiselect filters by package and level.
class DebugLogViewerScreen extends StatefulWidget {
  const DebugLogViewerScreen({super.key});

  @override
  State<DebugLogViewerScreen> createState() => _DebugLogViewerScreenState();
}

class _DebugLogViewerScreenState extends State<DebugLogViewerScreen> {
  Set<String> _selectedPrefixes = Set<String>.from(knownPrefixes);
  Set<Level> _selectedLevels = Set<Level>.from(knownLevels);

  List<SessionLogEntry> get _filtered =>
      SessionLogBuffer.instance.getFiltered(
        selectedPrefixes: _selectedPrefixes,
        selectedLevels: _selectedLevels,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Package:', style: theme.textTheme.titleSmall),
          const SizedBox(width: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: knownPrefixes.map((p) {
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
          const SizedBox(width: 16),
          Text('Level:', style: theme.textTheme.titleSmall),
          const SizedBox(width: 8),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
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

  Color _levelColor(Level level) {
    switch (level) {
      case Level.error:
        return Colors.red;
      case Level.warning:
        return Colors.orange;
      case Level.info:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
