import 'package:flutter/material.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../widgets/ct_resource_cell.dart';
import '../../../../widgets/ct_spacing.dart';
import 'production_commodity_breakdown_dialog.dart';

TextStyle productionBreakdownHeadingStyle(BuildContext context) {
  final TextStyle base =
      Theme.of(context).textTheme.labelSmall ?? const TextStyle(fontSize: 11);
  return base.copyWith(
    color: EditorialMonoclePalette.muted,
    fontWeight: FontWeight.w600,
  );
}

TextStyle productionBreakdownSectionHeaderStyle(BuildContext context) {
  final TextStyle base =
      Theme.of(context).textTheme.labelSmall ?? const TextStyle(fontSize: 11);
  return base.copyWith(
    color: EditorialMonoclePalette.muted,
    fontWeight: FontWeight.w600,
    fontFeatures: const <FontFeature>[FontFeature.enable('smcp')],
  );
}

TextStyle productionBreakdownCommodityNameStyle(BuildContext context) {
  final TextStyle base =
      Theme.of(context).textTheme.bodySmall ?? const TextStyle(fontSize: 12);
  return base.copyWith(color: EditorialMonoclePalette.fg);
}

TextStyle productionBreakdownDeltaCellStyle(BuildContext context, int value) {
  final TextStyle base =
      Theme.of(context).textTheme.labelMedium ?? const TextStyle(fontSize: 12);
  final Color? color = CtResourceCell.deltaColor(value);
  return base.copyWith(
    color: color ?? EditorialMonoclePalette.muted,
    fontFamilyFallback: const <String>['SF Mono', 'Menlo', 'monospace'],
    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
  );
}

Widget productionBreakdownDeltaCell(BuildContext context, int value) {
  return Text(
    ProductionCommodityBreakdownDialog.formatDelta(value),
    maxLines: 1,
    style: productionBreakdownDeltaCellStyle(context, value),
  );
}

Widget productionBreakdownSectionHeaderCell(
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
        style: productionBreakdownSectionHeaderStyle(context),
      ),
    ),
  );
}
