import 'package:flutter/material.dart';

import '../../../../../config/ct_e2e.dart';
import '../../../../../config/editorial_monocle_palette.dart';
import '../../../../../widgets/ct_panel.dart';
import '../../../../../widgets/ct_spacing.dart';
import '../../../../../widgets/ct_top_bar.dart';

/// Shared layout: constrained panel, [CtPanel], dark editorial-monocle
/// [CtTopBar] title chrome, and list or empty state.
///
/// Implements `Refs #2866` S1 shared chrome: the title row is rendered via
/// [CtTopBar] (`showBackButton: false`) so all three unit panels (civilian,
/// military, naval) inherit the canonical 36 px gradient bar + 1 px
/// `--accent-dim` bottom border and `--accent` title colour from #2858 /
/// #2859. The empty-state message resolves to [EditorialMonoclePalette.muted]
/// in italic so the empty surface keeps the dark-theme palette instead of
/// the default Material `onSurfaceVariant` token.
class UnitsPanelShell extends StatelessWidget {
  const UnitsPanelShell({
    super.key,
    required this.title,
    this.actions = const [],
    required this.hasContent,
    required this.listChildren,
    required this.emptyMessage,
    this.listPadding = const EdgeInsets.fromLTRB(
      CtSpacing.m,
      0,
      CtSpacing.m,
      CtSpacing.m,
    ),
    this.panelConstraints = defaultPanelConstraints,
  });

  final String title;
  final List<Widget> actions;
  final bool hasContent;
  final List<Widget> listChildren;
  final String emptyMessage;
  final EdgeInsets listPadding;
  final BoxConstraints panelConstraints;

  static const BoxConstraints defaultPanelConstraints = BoxConstraints(
    maxWidth: 400,
    maxHeight: 500,
  );

  /// Horizontal gap between trailing actions in the [CtTopBar] trailing slot.
  static const double _trailingActionsSpacing = 4;

  Widget? _buildTrailing() {
    if (actions.isEmpty) {
      return null;
    }
    if (actions.length == 1) {
      return actions.first;
    }
    final List<Widget> spaced = <Widget>[];
    for (int i = 0; i < actions.length; i++) {
      if (i > 0) {
        spaced.add(const SizedBox(width: _trailingActionsSpacing));
      }
      spaced.add(actions[i]);
    }
    return Row(mainAxisSize: MainAxisSize.min, children: spaced);
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: panelConstraints,
      child: Padding(
        padding: const EdgeInsets.all(CtSpacing.m),
        child: CtPanel(
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CtTopBar(
                title: title,
                showBackButton: false,
                trailing: _buildTrailing(),
              ),
              Flexible(
                child: hasContent
                    ? ListView(
                        shrinkWrap: true,
                        // E2E panel-text assertions walk the full ListView
                        // preorder; a tall unit roster virtualizes rows below the
                        // fold. A generous cache keeps every row built once the
                        // test helper has scrolled through the list (Refs #2336).
                        cacheExtent: kCtE2EEnabled ? 10000 : null,
                        padding: listPadding,
                        children: listChildren,
                      )
                    : Padding(
                        padding: const EdgeInsets.all(CtSpacing.xxl),
                        child: Center(
                          child: Text(
                            emptyMessage,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: EditorialMonoclePalette.muted,
                                  fontStyle: FontStyle.italic,
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
