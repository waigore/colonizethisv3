import 'package:flutter/material.dart';

import '../../../../../widgets/ct_panel.dart';

/// Shared layout: constrained panel, [CtPanel], title row, and list or empty state.
class UnitsPanelShell extends StatelessWidget {
  const UnitsPanelShell({
    super.key,
    required this.title,
    this.actions = const [],
    required this.hasContent,
    required this.listChildren,
    required this.emptyMessage,
    this.listPadding = const EdgeInsets.fromLTRB(8, 0, 8, 8),
  });

  final String title;
  final List<Widget> actions;
  final bool hasContent;
  final List<Widget> listChildren;
  final String emptyMessage;
  final EdgeInsets listPadding;

  static const BoxConstraints panelConstraints = BoxConstraints(
    maxWidth: 400,
    maxHeight: 500,
  );

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: panelConstraints,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: CtPanel(
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    ...actions,
                  ],
                ),
              ),
              Flexible(
                child: hasContent
                    ? ListView(
                        shrinkWrap: true,
                        padding: listPadding,
                        children: listChildren,
                      )
                    : Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            emptyMessage,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
