import 'package:flutter/material.dart';

import 'ct_panel_with_top_bar.dart';
import 'ct_spacing.dart';
import 'ct_top_bar.dart';

/// Full-screen pixel-art shell: dark editorial-monocle background + framed
/// content area + 36 px [CtTopBar].
///
/// Per `Refs #2859` R4 / S5, the legacy [Scaffold]+[AppBar]-style top bar
/// (full-width [colorScheme.primary] band with [Icons.arrow_back]) is
/// replaced by [CtTopBar] so the dark theme palette, [CtGradients]
/// `topBarGradient`, and [CtBackButton] chevron all participate via a
/// single shared primitive. The existing public API is preserved:
/// callers still pass [title], [child], and [showBackButton] and continue
/// to get a screen-shell with title + body framing. SPEC:
/// `SPEC/ui/pixel-art-ui-catalog.md` § Pixel-art component catalog
/// (`CtScreenShell` entry).
class CtScreenShell extends StatelessWidget {
  const CtScreenShell({
    super.key,
    required this.title,
    required this.child,
    this.showBackButton = false,
    this.showTitleBar = true,
  });

  final String title;
  final Widget child;
  final bool showBackButton;

  /// When `false`, the [CtTopBar] title band is omitted so the shell frames
  /// the [child] without a secondary title row. Used by the in-game map
  /// shell, whose own 36 dp top bar is the only chrome the mockup shows
  /// (issue #2861 M2 / `SPEC/ui/game-screen.md` § In-game shell title band).
  final bool showTitleBar;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(CtSpacing.m),
          child: CtPanelWithTopBar(
            topBar: showTitleBar
                ? CtTopBar(
                    title: title,
                    showBackButton: showBackButton,
                  )
                : null,
            children: <Widget>[
              if (showTitleBar) const SizedBox(height: CtSpacing.m),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CtSpacing.m,
                  ),
                  child: child,
                ),
              ),
              const SizedBox(height: CtSpacing.m),
            ],
          ),
        ),
      ),
    );
  }
}
