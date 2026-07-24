import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../widgets/resource_icon.dart';
import 'commodity_ui_helpers.dart';
import 'production_commodity_breakdown_dialog.dart';
import 'production_commodity_breakdown_dialog_table.dart';
import 'production_commodity_breakdown_dialog_table_cells.dart';

extension ProductionBreakdownTableBodyData on ProductionBreakdownTableBody {
  DataTable buildProductionBreakdownDataTable(
    BuildContext context,
    List<double>? columnContentWidths,
  ) {
    final phaseColCount = EconomyPreviewStockpilePhase.values.length;
    final dividerColor =
        EditorialMonoclePalette.accentDim.withValues(alpha: 0.5);
    var commodityRowIndex = 0;

    Widget sizedCell(int columnIndex, Widget child) {
      if (columnContentWidths == null) return child;
      return SizedBox(width: columnContentWidths[columnIndex], child: child);
    }

    Widget sizedHeader(int columnIndex, Widget child) {
      if (columnContentWidths == null) return child;
      return SizedBox(
        key: ValueKey<String>('prodBreakdownHeaderCol_$columnIndex'),
        width: columnContentWidths[columnIndex],
        child: child,
      );
    }

    List<DataRow> rowsFor(List<Commodity> list) {
      return list.map((c) {
        final total = rowTotal(c.id);
        final name = commodityDisplayName(l10n, c.id);
        final rowShade = commodityRowIndex.isEven
            ? Colors.transparent
            : EditorialMonoclePalette.surface.withValues(alpha: 0.4);
        commodityRowIndex += 1;
        return DataRow(
          color: WidgetStatePropertyAll<Color?>(rowShade),
          cells: [
            DataCell(
              sizedCell(
                0,
                Row(
                  children: [
                    ResourceIcon(commodityId: c.id, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: productionBreakdownCommodityNameStyle(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ...EconomyPreviewStockpilePhase.values.indexed.map(
              (entry) => DataCell(
                sizedCell(
                  1 + entry.$1,
                  productionBreakdownDeltaCell(
                    context,
                    phaseValue(c.id, entry.$2),
                  ),
                ),
              ),
            ),
            DataCell(
              sizedCell(
                phaseColCount + 1,
                productionBreakdownDeltaCell(context, total),
              ),
            ),
          ],
        );
      }).toList();
    }

    return DataTable(
      headingRowHeight: 40,
      dataRowMinHeight: 32,
      dataRowMaxHeight: 48,
      dividerThickness: 1,
      columnSpacing: ProductionBreakdownTableBody.tableColumnSpacing,
      horizontalMargin: ProductionBreakdownTableBody.tableHorizontalMargin,
      headingRowColor: WidgetStatePropertyAll<Color?>(
        EditorialMonoclePalette.surfaceLite,
      ),
      border: TableBorder(
        horizontalInside: BorderSide(color: dividerColor),
      ),
      headingTextStyle: productionBreakdownHeadingStyle(context),
      columns: [
        DataColumn(
          label: sizedHeader(0, Text(l10n.production_breakdown_commodity)),
        ),
        ...EconomyPreviewStockpilePhase.values.indexed.map(
          (entry) => DataColumn(
            label: sizedHeader(
              1 + entry.$1,
              Text(
                ProductionCommodityBreakdownDialog.phaseColumnLabel(
                  l10n,
                  entry.$2,
                ),
                softWrap: true,
              ),
            ),
          ),
        ),
        DataColumn(
          label: sizedHeader(
            phaseColCount + 1,
            Text(l10n.production_breakdown_total),
          ),
        ),
      ],
      rows: [
        for (final (label, commodities) in sections)
          if (commodities.isNotEmpty) ...[
            DataRow(
              cells: [
                DataCell(
                  sizedCell(
                    0,
                    productionBreakdownSectionHeaderCell(context, label),
                  ),
                ),
                ...List<DataCell>.generate(
                  phaseColCount + 1,
                  (i) => DataCell(
                    sizedCell(1 + i, const SizedBox.shrink()),
                  ),
                ),
              ],
            ),
            ...rowsFor(commodities),
          ],
      ],
    );
  }
}
