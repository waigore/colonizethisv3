/// Political section assembly and owner/region display helpers.
library;


import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import 'province_sea_zone_detail_overlay_support.dart';
import 'package:colonizethis_world/colonizethis_world.dart' show WorldStateProvinceLookup, kRegionNewWorld, kRegionOldWorld;

String ownerNameForProvinceOverlay(
  AppLocalizations l10n,
  Game game,
  String? ownerId,
) {
  if (ownerId == null || ownerId.isEmpty) {
    return l10n.provinceOverlay_ownerUnclaimed;
  }
  for (final p in game.players) {
    if (p.id == ownerId) return p.displayName;
  }
  for (final m in game.minorNations) {
    if (m.id == ownerId) return m.displayName ?? m.id;
  }
  for (final t in game.tribes) {
    if (t.id == ownerId) return t.displayName ?? t.id;
  }
  return ownerId;
}

@visibleForTesting
String provinceOverlayOwnerName(
  AppLocalizations l10n,
  Game game,
  String? ownerId,
) =>
    ownerNameForProvinceOverlay(l10n, game, ownerId);

String provinceOverlayRegionLabel(AppLocalizations l10n, String regionId) {
  return switch (regionId) {
    kRegionOldWorld => l10n.region_oldWorld,
    kRegionNewWorld => l10n.region_newWorld,
    _ => regionId,
  };
}

@visibleForTesting
String provinceOverlayTownDevelopmentGist(
  AppLocalizations l10n,
  int townDevelopmentLevel,
) {
  return switch (townDevelopmentLevel) {
    kTownDevelopmentLevelMax =>
      l10n.provinceOverlay_townDevelopmentGistMax,
    2 => l10n.provinceOverlay_townDevelopmentGistBonusActiveNextAt4,
    3 => l10n.provinceOverlay_townDevelopmentGistNextAt4,
    _ => l10n.provinceOverlay_townDevelopmentGistNextAt2,
  };
}

Widget buildPoliticalSection({
  required AppLocalizations l10n,
  required String name,
  required String ownerName,
  required String regionLabel,
  required bool isCapital,
  required int townDevelopmentLevel,
  required bool showUpgradeTownControl,
  required bool upgradeTownEnabled,
  required String upgradeTownTooltip,
  VoidCallback? onUpgradeTownTap,
}) {
  final bodyStyle = overlayFgBodyStyle();
  final gistStyle = bodyStyle.copyWith(
    color: EditorialMonoclePalette.muted,
    fontSize: 12,
  );
  return buildOverlaySection(
    l10n.provinceOverlay_sectionPolitical,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.provinceOverlay_name(name), style: bodyStyle),
        Text(l10n.provinceOverlay_owner(ownerName), style: bodyStyle),
        Text(l10n.provinceOverlay_region(regionLabel), style: bodyStyle),
        Text(
          isCapital
              ? l10n.provinceOverlay_capitalYes
              : l10n.provinceOverlay_capitalNo,
          style: bodyStyle,
        ),
        Text(
          l10n.provinceOverlay_townDevelopmentOfMax(
            townDevelopmentLevel,
            kTownDevelopmentLevelMax,
          ),
          style: bodyStyle,
        ),
        Text(
          provinceOverlayTownDevelopmentGist(l10n, townDevelopmentLevel),
          style: gistStyle,
        ),
        if (showUpgradeTownControl)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: CtActionTextButton(
              label: l10n.provinceOverlay_upgradeTownAction,
              tooltip: upgradeTownTooltip,
              enabled: upgradeTownEnabled,
              onPressed: upgradeTownEnabled ? onUpgradeTownTap : null,
            ),
          ),
      ],
    ),
  );
}

Province? findProvinceForSeaZoneOverlay(Game game, String provinceId) =>
    game.worldState.allProvincesById[provinceId];
