/// Cell chrome helpers for [ProductionBreakdownTableBody].

part of 'production_commodity_breakdown_dialog.dart';

TextStyle _productionBreakdownHeadingStyle(BuildContext context) {
  final TextStyle base =
      Theme.of(context).textTheme.labelSmall ?? const TextStyle(fontSize: 11);
  return base.copyWith(
    color: EditorialMonoclePalette.muted,
    fontWeight: FontWeight.w600,
  );
}

TextStyle _productionBreakdownSectionHeaderStyle(BuildContext context) {
  final TextStyle base =
      Theme.of(context).textTheme.labelSmall ?? const TextStyle(fontSize: 11);
  return base.copyWith(
    color: EditorialMonoclePalette.muted,
    fontWeight: FontWeight.w600,
    fontFeatures: const <FontFeature>[FontFeature.enable('smcp')],
  );
}

TextStyle _productionBreakdownCommodityNameStyle(BuildContext context) {
  final TextStyle base =
      Theme.of(context).textTheme.bodySmall ?? const TextStyle(fontSize: 12);
  return base.copyWith(color: EditorialMonoclePalette.fg);
}

TextStyle _productionBreakdownDeltaCellStyle(BuildContext context, int value) {
  final TextStyle base =
      Theme.of(context).textTheme.labelMedium ?? const TextStyle(fontSize: 12);
  final Color? color = CtResourceCell.deltaColor(value);
  return base.copyWith(
    color: color ?? EditorialMonoclePalette.muted,
    fontFamilyFallback: const <String>['SF Mono', 'Menlo', 'monospace'],
    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
  );
}

Widget _productionBreakdownDeltaCell(BuildContext context, int value) {
  return Text(
    ProductionCommodityBreakdownDialog.formatDelta(value),
    maxLines: 1,
    style: _productionBreakdownDeltaCellStyle(context, value),
  );
}

Widget _productionBreakdownSectionHeaderCell(
  BuildContext context,
  String label,
) {
  return DecoratedBox(
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(
          color: EditorialMonoclePalette.accentDim,
          width: 1,
        ),
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.only(bottom: CtSpacing.xs),
      child: Text(
        label.toUpperCase(),
        style: _productionBreakdownSectionHeaderStyle(context),
      ),
    ),
  );
}
