import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/ct_section_label.dart';
import '../../../../widgets/ct_spacing.dart';
import '../../../../widgets/resource_icon.dart';

/// Overview strip: extraction projection + idle civilian counts.
class DevelopmentPanelOverview extends StatelessWidget {
  const DevelopmentPanelOverview({
    super.key,
    required this.regionModel,
  });

  final DevelopmentPanelRegionModel regionModel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final extractionParts = <Widget>[];
    for (final commodity in CommodityCatalog.all) {
      final qty = regionModel.landExtractionByCommodity[commodity.id];
      if (qty == null || qty <= 0) continue;
      extractionParts.add(
        Padding(
          padding: const EdgeInsets.only(right: CtSpacing.s),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ResourceIcon(commodityId: commodity.id, size: 14),
              const SizedBox(width: 4),
              Text(
                '$qty ${commodity.displayName}',
                style: textTheme.bodySmall?.copyWith(
                  color: EditorialMonoclePalette.fg,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CtSectionLabel('Extraction'),
        const SizedBox(height: 4),
        extractionParts.isEmpty
            ? Text(
                '—',
                style: textTheme.bodySmall?.copyWith(
                  color: EditorialMonoclePalette.muted,
                ),
              )
            : Wrap(children: extractionParts),
        const SizedBox(height: CtSpacing.m),
        Text(
          'Idle Builders: ${regionModel.idleBuilderCount} · '
          'Idle Engineers: ${regionModel.idleEngineerCount}',
          style: textTheme.bodySmall?.copyWith(
            color: EditorialMonoclePalette.muted,
          ),
        ),
      ],
    );
  }
}
