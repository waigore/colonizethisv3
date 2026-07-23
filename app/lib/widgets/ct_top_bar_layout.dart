part of 'ct_top_bar.dart';

extension _CtTopBarLayout on CtTopBar {
  TextStyle _titleStyle(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle base =
        theme.textTheme.titleMedium ?? const TextStyle(fontSize: 16);
    return base.copyWith(
      color: EditorialMonoclePalette.accent,
      letterSpacing: 0.05,
    );
  }

  TextStyle _backLabelStyle(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle base =
        theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14);
    final double opacity = backButtonEnabled
        ? 1.0
        : CtBackButton.disabledOpacity;
    return base.copyWith(
      color: EditorialMonoclePalette.muted.withValues(alpha: opacity),
    );
  }

  CtBackButton _buildBackButton() {
    if (backButtonSemanticLabel == null) {
      return CtBackButton(
        onPressed: onBackPressed,
        enabled: backButtonEnabled,
      );
    }
    return CtBackButton(
      onPressed: onBackPressed,
      enabled: backButtonEnabled,
      semanticLabel: backButtonSemanticLabel!,
    );
  }

  List<Widget> _buildRowChildren(BuildContext context) {
    final List<Widget> children = <Widget>[];
    if (showBackButton) {
      children.add(_buildBackButton());
      if (backButtonLabel != null) {
        children.add(const SizedBox(width: CtTopBar.leadingGap));
        children.add(
          Text(
            backButtonLabel!,
            style: _backLabelStyle(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }
      children.add(const SizedBox(width: CtTopBar.leadingGap));
    }
    if (icon != null) {
      children.add(icon!);
      children.add(const SizedBox(width: CtTopBar.iconGap));
    }
    children.add(
      Expanded(
        child: Text(
          title,
          style: _titleStyle(context),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
    if (trailing != null) {
      children.add(const SizedBox(width: CtTopBar.trailingGap));
      children.add(trailing!);
    }
    return children;
  }
}
