/// Minimum viewport width at which the breakdown dialog drops the
/// trailing horizontal `Scrollbar` + `SingleChildScrollView` and lets the
/// 7-column `DataTable` lay out without horizontal scroll.
///
/// SPEC/ui/production-commodity-breakdown-dialog.md § Layout (viewport-
/// adaptive dialog width). Refs #2862 S8c / C6.
const double kProductionBreakdownDialogWideViewportThreshold = 900;

/// `CtDialogShell.maxWidth` used when the surrounding viewport is at least
/// [kProductionBreakdownDialogWideViewportThreshold]. Chosen so the 7
/// column `DataTable` (`Commodity` + 5 phase columns + `Total`) lays out
/// without horizontal scroll at desktop / wide viewports while still
/// leaving comfortable insets on either side of the dialog frame.
///
/// SPEC/ui/production-commodity-breakdown-dialog.md § Layout (viewport-
/// adaptive dialog width). Refs #2862 S8c / C6.
const double kProductionBreakdownDialogWideMaxWidth = 900;

/// `CtDialogShell.maxWidth` used when the surrounding viewport is
/// strictly narrower than [kProductionBreakdownDialogWideViewportThreshold].
/// Keeps the historical narrow cap so the horizontal `Scrollbar` +
/// `SingleChildScrollView` fallback path remains the same on small
/// viewports.
///
/// SPEC/ui/production-commodity-breakdown-dialog.md § Layout (viewport-
/// adaptive dialog width). Refs #2862 S8c / C6.
const double kProductionBreakdownDialogNarrowMaxWidth = 720;

/// Computes the per-column content widths used on the wide-viewport path so the
/// 7-column breakdown `DataTable` fills the full `CtDialogShell` content column
/// instead of sizing to intrinsic content.
///
/// The returned list has `phaseColumnCount + 2` entries in column order
/// (`Commodity`, one per phase, `Total`). The `Commodity` column receives a
/// larger share (twice the per-numeric width) while the phase columns and the
/// trailing `Total` column share the remaining content budget evenly (owner
/// decision **B** on #3509). Width consumed by [horizontalMargin] (both outer
/// edges) and [columnSpacing] (between columns) is subtracted from the
/// distributed budget so the laid-out table width equals [availableWidth] with
/// no trailing gap.
///
/// The per-numeric width is floored so every phase / `Total` column is exactly
/// equal; the `Commodity` column absorbs the rounding remainder, keeping it
/// strictly wider than each numeric column and the summed content width exactly
/// equal to the budget. A non-positive or unbounded [availableWidth] falls back
/// to equal, non-negative widths so the caller never forces a negative
/// `SizedBox` width.
/// SPEC/ui/production-commodity-breakdown-dialog.md § Layout (wide-path
/// full-width column distribution). Refs #3509.
List<double> productionBreakdownWideColumnContentWidths({
  required double availableWidth,
  required int phaseColumnCount,
  required double columnSpacing,
  required double horizontalMargin,
}) {
  final int numericColumns = phaseColumnCount + 1; // phases + Total
  final int totalColumns = phaseColumnCount + 2; // + Commodity
  final double chrome =
      horizontalMargin * 2 + columnSpacing * (totalColumns - 1);
  final double contentBudget = availableWidth - chrome;
  const int commodityShares = 2;
  final int totalShares = commodityShares + numericColumns;
  if (!contentBudget.isFinite || contentBudget <= 0 || totalShares <= 0) {
    final double fallback =
        (!contentBudget.isFinite || contentBudget <= 0)
            ? 0
            : contentBudget / totalColumns;
    return List<double>.filled(totalColumns, fallback);
  }
  final double numericWidth = (contentBudget / totalShares).floorToDouble();
  final double commodityWidth = contentBudget - numericWidth * numericColumns;
  return <double>[
    commodityWidth,
    for (var i = 0; i < phaseColumnCount; i++) numericWidth,
    numericWidth,
  ];
}
