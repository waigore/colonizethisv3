import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app/widgets/ct_icon_action.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import '../unit_orders/move_army_invasion_intel_labels.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/build_fort_payoff_gist_line.dart';
import 'province_panel_labels.dart';
import 'province_panel_pending_orders.dart';
import 'province_sea_zone_detail_overlay_sections_political.dart';
import 'province_sea_zone_detail_overlay_support.dart';
import 'province_sea_zone_detail_overlay_tile_section_labels.dart'
    show kProvinceOverlayTileInlineActionDisabledAlpha;

Widget buildMilitarySectionByOwner({
  required AppLocalizations l10n,
  required Game game,
  required List<Unit> military,
  required String humanPlayerId,
  required String provinceId,
  required Orders draftOrders,
  required int fortLevel,
  required bool showBuildFortActionIcon,
  required bool buildFortActionEnabled,
  required String buildFortTooltip,
  String? buildFortPayoffGist,
  VoidCallback? onBuildFortTap,
  bool showMoveArmyControl = false,
  bool moveArmyEnabled = false,
  String moveArmyTooltip = '',
  VoidCallback? onMoveArmyTap,
  bool showInvadeArmyControl = false,
  bool invadeArmyEnabled = false,
  String invadeArmyTooltip = '',
  VoidCallback? onInvadeArmyTap,
  bool showCombineArmiesControl = false,
  bool combineArmiesEnabled = false,
  String combineArmiesTooltip = '',
  VoidCallback? onCombineArmiesTap,
  String? provinceDisplayName,
}) {
  final pending = provincePanelPendingMilitaryLines(
    game: game,
    orders: draftOrders,
    provinceId: provinceId,
    humanPlayerId: humanPlayerId,
    l10n: l10n,
  );
  final fortLine = moveArmyFortLabelForLevel(l10n, fortLevel);
  final fortStatusRow = Row(
    children: [
      Expanded(
        child: Text(
          l10n.provinceOverlay_militaryFortStatus(fortLine),
          style: TextStyle(color: EditorialMonoclePalette.fg),
        ),
      ),
      if (showBuildFortActionIcon)
        CtIconAction(
          tooltip: buildFortTooltip,
          onPressed: buildFortActionEnabled ? onBuildFortTap : null,
          icon: Icons.castle,
          enabled: buildFortActionEnabled,
          disabledIconColor: EditorialMonoclePalette.muted.withValues(
            alpha: kProvinceOverlayTileInlineActionDisabledAlpha,
          ),
        ),
    ],
  );
  final fortStatusBlock = Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      fortStatusRow,
      if (buildFortPayoffGist != null && buildFortPayoffGist.isNotEmpty)
        BuildFortPayoffGistLine(text: buildFortPayoffGist),
    ],
  );
  final moveInvadeActions = <Widget>[
    if (showMoveArmyControl)
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: CtActionTextButton(
          label: l10n.provinceOverlay_moveArmyAction,
          tooltip: moveArmyTooltip,
          enabled: moveArmyEnabled,
          onPressed: moveArmyEnabled ? onMoveArmyTap : null,
        ),
      ),
    if (showInvadeArmyControl)
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: CtActionTextButton(
          label: l10n.provinceOverlay_invadeArmyAction(
            provinceDisplayName ?? provinceId,
          ),
          tooltip: invadeArmyTooltip,
          enabled: invadeArmyEnabled,
          onPressed: invadeArmyEnabled ? onInvadeArmyTap : null,
        ),
      ),
    if (showCombineArmiesControl)
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: CtActionTextButton(
          label: l10n.provinceOverlay_combineArmiesAction,
          tooltip: combineArmiesTooltip,
          enabled: combineArmiesEnabled,
          onPressed: combineArmiesEnabled ? onCombineArmiesTap : null,
        ),
      ),
  ];
  if (military.isEmpty && pending.isEmpty) {
    return buildOverlaySection(
      l10n.provinceOverlay_sectionMilitary,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [fortStatusBlock, ...moveInvadeActions],
      ),
    );
  }
  if (military.isEmpty) {
    return buildOverlaySection(
      l10n.provinceOverlay_sectionMilitary,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          fortStatusBlock,
          ...moveInvadeActions,
          ...pending.map(
            (line) => Padding(
              padding: const EdgeInsets.only(left: CtSpacing.m / 2),
              child: Text(
                line,
                style: TextStyle(color: EditorialMonoclePalette.muted),
              ),
            ),
          ),
        ],
      ),
    );
  }
  final byOwner = <String, List<Unit>>{};
  for (final u in military) {
    byOwner.putIfAbsent(u.ownerId, () => []).add(u);
  }
  final ownerIds = byOwner.keys.toList()
    ..sort((a, b) {
      if (a == humanPlayerId) return -1;
      if (b == humanPlayerId) return 1;
      return ownerNameForProvinceOverlay(
        l10n,
        game,
        a,
      ).compareTo(ownerNameForProvinceOverlay(l10n, game, b));
    });
  return buildOverlaySection(
    l10n.provinceOverlay_sectionMilitary,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        fortStatusBlock,
        ...moveInvadeActions,
        const SizedBox(height: CtSpacing.m / 2),
        ...ownerIds.map((oid) {
          final list = byOwner[oid]!;
          final byType = <String, int>{};
          for (final u in list) {
            byType[u.type] = (byType[u.type] ?? 0) + 1;
          }
          final name = ownerNameForProvinceOverlay(l10n, game, oid);
          return Padding(
            padding: const EdgeInsets.only(bottom: CtSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: EditorialMonoclePalette.fg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                ...byType.entries.map((e) {
                  final label = regimentTypeDisplayLabel(l10n, e.key);
                  return Text(
                    l10n.provinceOverlay_indentedCount(label, e.value),
                    style: TextStyle(color: EditorialMonoclePalette.fg),
                  );
                }),
              ],
            ),
          );
        }),
        if (pending.isNotEmpty) ...[
          const SizedBox(height: CtSpacing.m / 2),
          ...pending.map(
            (line) => Padding(
              padding: const EdgeInsets.only(left: CtSpacing.m / 2),
              child: Text(
                line,
                style: TextStyle(color: EditorialMonoclePalette.muted),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}
