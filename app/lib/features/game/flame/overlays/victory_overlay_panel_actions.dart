part of 'victory_overlay.dart';

extension _VictoryPanelActions on VictoryPanel {
  Widget buildActionRow(
    BuildContext context,
    AppLocalizations l10n, {
    required bool narrow,
  }) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? secondaryButtonStyle = theme.textTheme.titleSmall?.copyWith(
      color: EditorialMonoclePalette.muted,
    );
    final Widget primary = CtNinePatchButton(
      onPressed: () => bus.emit(const ct_models.NavigateToShellEvent()),
      child: Text(l10n.victory_returnToMainMenu),
    );
    final Widget secondary = CtNinePatchButton(
      onPressed: () {
        onViewFinalState?.call();
      },
      child: Text(
        l10n.victory_viewFinalState,
        style: secondaryButtonStyle,
      ),
    );
    if (narrow) {
      // SPEC/ui/victory-overlay.md § Narrow viewport: stacked vertical Column
      // mirroring the mockup's `flex-wrap:wrap` + `min-width:clamp(120,...)`
      // collapse to a single column at narrow widths.
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          primary,
          const SizedBox(height: 8),
          secondary,
        ],
      );
    }
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: <Widget>[primary, secondary],
    );
  }
}

/// Three-glyph laurel decoration sitting above the victory-type label. Uses
/// Unicode glyphs in `--accent` at 0.6 alpha (no asset dependency).
///
/// Renders at [VictoryPanel.laurelFontSizeNarrow] when [narrow] is true and at
/// [VictoryPanel.laurelFontSizeWide] otherwise. SPEC/ui/victory-overlay.md
/// § Narrow viewport pins both values (lower-bound of the mockup's
/// `clamp(24px,5vw,36px)` for narrow; default for wide).
class _VictoryLaurelRow extends StatelessWidget {
  const _VictoryLaurelRow({required this.narrow});

  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final double fontSize = narrow
        ? VictoryPanel.laurelFontSizeNarrow
        : VictoryPanel.laurelFontSizeWide;
    final TextStyle laurelStyle = TextStyle(
      color: EditorialMonoclePalette.accent.withValues(alpha: 0.6),
      fontSize: fontSize,
      height: 1,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text('\u269C', style: laurelStyle),
        const SizedBox(width: 6),
        Text('\u2605', style: laurelStyle),
        const SizedBox(width: 6),
        Text('\u269C', style: laurelStyle),
      ],
    );
  }
}
