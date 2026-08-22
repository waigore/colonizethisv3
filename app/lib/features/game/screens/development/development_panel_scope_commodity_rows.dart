import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart'
    show DevelopmentImprovableCommodityRow;
import 'package:colonizethis_orders/colonizethis_orders.dart'
    show DevelopmentAssignRowState, DevelopmentImproveAssignCandidate;
import 'package:flutter/material.dart';

import '../../../../widgets/commodity_display_name.dart';
import '../../../../widgets/ct_action_text_button.dart';
import '../../../../widgets/ct_spacing.dart';
import 'development_assign_preview.dart';
import 'development_panel_keys.dart';

class DevelopmentImprovableCommodityRowView extends StatelessWidget {
  const DevelopmentImprovableCommodityRowView({
    super.key,
    required this.l10n,
    required this.scopeKey,
    required this.row,
    required this.textTheme,
    required this.assignRowStateFor,
    required this.onShowTiles,
    required this.onAssign,
    required this.provinceDisplayNamesById,
  });

  final AppLocalizations l10n;
  final String scopeKey;
  final DevelopmentImprovableCommodityRow row;
  final TextTheme textTheme;
  final DevelopmentAssignRowState Function(String scopeKey, String commodityId)
  assignRowStateFor;
  final void Function(Set<String> tileKeys, {String? selectedTileKey})
  onShowTiles;
  final void Function(DevelopmentImproveAssignCandidate candidate) onAssign;
  final Map<String, String> provinceDisplayNamesById;

  @override
  Widget build(BuildContext context) {
    final displayName = commodityDisplayName(l10n, row.commodityId);
    final assignState = assignRowStateFor(scopeKey, row.commodityId);
    final previewLine = formatDevelopmentAssignPreviewLine(
      l10n: l10n,
      assignState: assignState,
      provinceDisplayNamesById: provinceDisplayNamesById,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DevelopmentImprovableCommodityActionsRow(
            l10n: l10n,
            scopeKey: scopeKey,
            row: row,
            textTheme: textTheme,
            displayName: displayName,
            assignState: assignState,
            onShowTiles: onShowTiles,
            onAssign: onAssign,
          ),
          if (previewLine != null)
            DevelopmentAssignPreviewCaption(
              scopeKey: scopeKey,
              commodityId: row.commodityId,
              previewLine: previewLine,
              textTheme: textTheme,
            ),
        ],
      ),
    );
  }
}

class DevelopmentImprovableCommodityActionsRow extends StatelessWidget {
  const DevelopmentImprovableCommodityActionsRow({
    super.key,
    required this.l10n,
    required this.scopeKey,
    required this.row,
    required this.textTheme,
    required this.displayName,
    required this.assignState,
    required this.onShowTiles,
    required this.onAssign,
  });

  final AppLocalizations l10n;
  final String scopeKey;
  final DevelopmentImprovableCommodityRow row;
  final TextTheme textTheme;
  final String displayName;
  final DevelopmentAssignRowState assignState;
  final void Function(Set<String> tileKeys, {String? selectedTileKey})
  onShowTiles;
  final void Function(DevelopmentImproveAssignCandidate candidate) onAssign;

  @override
  Widget build(BuildContext context) {
    final assignTooltip = assignState.disabledReason;
    final assignButton = CtActionTextButton(
      key: DevelopmentPanelKeys.assignButtonKey(scopeKey, row.commodityId),
      label: l10n.civilian_units_assign,
      onPressed: assignState.enabled && assignState.candidate != null
          ? () => onAssign(assignState.candidate!)
          : null,
    );
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.development_improvableCount(row.count, displayName),
            style: textTheme.bodySmall,
          ),
        ),
        CtActionTextButton(
          key: DevelopmentPanelKeys.showButtonKey(scopeKey, row.commodityId),
          label: l10n.development_show,
          onPressed: () => onShowTiles(
            row.tileKeys.toSet(),
            selectedTileKey: assignState.candidate?.targetTileKey,
          ),
        ),
        const SizedBox(width: CtSpacing.s),
        if (assignTooltip != null && !assignState.enabled)
          Tooltip(message: assignTooltip, child: assignButton)
        else
          assignButton,
      ],
    );
  }
}
