import 'package:flutter/material.dart';

import 'ct_panel.dart';

/// Shared inner skeleton: a [CtPanel] (zero padding) wrapping a
/// `Column(crossAxisAlignment: stretch)` whose first child is an optional
/// [topBar] followed by [children].
///
/// Extracted from the duplicated `CtPanel` > `Column` > `[CtTopBar, content]`
/// idiom shared by [`CtScreenShell`] and [`UnitsPanelShell`] (issue #3279 §5).
/// The two consumers differ only in their outer frame ([Scaffold]+[SafeArea]
/// vs [ConstrainedBox]), the column [mainAxisSize], and how the body sizes
/// itself ([Expanded] vs [Flexible]) — so those stay with the callers while
/// the common inner panel skeleton lives here.
///
/// SPEC: `SPEC/ui/components/ct-panel-with-top-bar.md`.
class CtPanelWithTopBar extends StatelessWidget {
  const CtPanelWithTopBar({
    super.key,
    this.topBar,
    required this.children,
    this.mainAxisSize = MainAxisSize.max,
  });

  /// Optional top chrome rendered as the first column child (typically a
  /// `CtTopBar`). When `null`, only [children] are mounted so callers can
  /// suppress the title band (e.g. the in-game map shell).
  final Widget? topBar;

  /// Column body rendered below [topBar]. Callers own any [Expanded] /
  /// [Flexible] wrapping and inter-child spacing so the exact layout of each
  /// consumer is preserved.
  final List<Widget> children;

  /// Forwarded to the inner [Column]. Both [CtScreenShell] and
  /// [UnitsPanelShell] use the default [MainAxisSize.max] so the body fills
  /// the available height ([CtScreenShell] fills a [Scaffold] body;
  /// [UnitsPanelShell] fills the host-allocated bottom-sheet cap, Refs #3627).
  final MainAxisSize mainAxisSize;

  @override
  Widget build(BuildContext context) {
    return CtPanel(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: mainAxisSize,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[?topBar, ...children],
      ),
    );
  }
}
