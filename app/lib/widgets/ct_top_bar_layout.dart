import 'package:flutter/material.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'ct_back_button.dart';
import 'ct_top_bar.dart';

TextStyle ctTopBarTitleStyle(BuildContext context) {
  final ThemeData theme = Theme.of(context);
  final TextStyle base =
      theme.textTheme.titleMedium ?? const TextStyle(fontSize: 16);
  return base.copyWith(
    color: EditorialMonoclePalette.accent,
    letterSpacing: 0.05,
  );
}

TextStyle ctTopBarBackLabelStyle(BuildContext context, CtTopBar bar) {
  final ThemeData theme = Theme.of(context);
  final TextStyle base =
      theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14);
  final double opacity =
      bar.backButtonEnabled ? 1.0 : CtBackButton.disabledOpacity;
  return base.copyWith(
    color: EditorialMonoclePalette.muted.withValues(alpha: opacity),
  );
}

CtBackButton buildCtTopBarBackButton(CtTopBar bar) {
  if (bar.backButtonSemanticLabel == null) {
    return CtBackButton(
      onPressed: bar.onBackPressed,
      enabled: bar.backButtonEnabled,
    );
  }
  return CtBackButton(
    onPressed: bar.onBackPressed,
    enabled: bar.backButtonEnabled,
    semanticLabel: bar.backButtonSemanticLabel!,
  );
}

List<Widget> buildCtTopBarRowChildren(CtTopBar bar, BuildContext context) {
  final List<Widget> children = <Widget>[];
  if (bar.showBackButton) {
    children.add(buildCtTopBarBackButton(bar));
    if (bar.backButtonLabel != null) {
      children.add(const SizedBox(width: CtTopBar.leadingGap));
      children.add(
        Text(
          bar.backButtonLabel!,
          style: ctTopBarBackLabelStyle(context, bar),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
    children.add(const SizedBox(width: CtTopBar.leadingGap));
  }
  if (bar.icon != null) {
    children.add(bar.icon!);
    children.add(const SizedBox(width: CtTopBar.iconGap));
  }
  children.add(
    Expanded(
      child: Text(
        bar.title,
        style: ctTopBarTitleStyle(context),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  );
  if (bar.trailing != null) {
    children.add(const SizedBox(width: CtTopBar.trailingGap));
    children.add(bar.trailing!);
  }
  return children;
}
