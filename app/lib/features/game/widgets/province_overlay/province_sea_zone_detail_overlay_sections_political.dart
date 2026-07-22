/// Political section assembly and owner/region display helpers.

import 'package:colonizethis_logic/colonizethis_logic.dart'
    show WorldStateProvinceLookup, kRegionNewWorld, kRegionOldWorld;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';

import 'province_sea_zone_detail_overlay_support.dart';

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

Widget buildPoliticalSection({
  required AppLocalizations l10n,
  required String name,
  required String ownerName,
  required String regionLabel,
  required bool isCapital,
  required int townDevelopmentLevel,
}) {
  final bodyStyle = overlayFgBodyStyle();
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
          l10n.provinceOverlay_townDevelopment(townDevelopmentLevel),
          style: bodyStyle,
        ),
      ],
    ),
  );
}

Province? findProvinceForSeaZoneOverlay(Game game, String provinceId) =>
    game.worldState.allProvincesById[provinceId];
