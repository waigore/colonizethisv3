import 'package:flutter/material.dart';

import 'ct_panel.dart';
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
  });

  final String title;
  final Widget child;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(CtSpacing.m),
          child: CtPanel(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                CtTopBar(
                  title: title,
                  showBackButton: showBackButton,
                ),
                const SizedBox(height: CtSpacing.m),
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
      ),
    );
  }
}
