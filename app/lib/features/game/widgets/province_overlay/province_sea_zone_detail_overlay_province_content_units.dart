/// Fog-gated military / civilian / naval sections for province tab content.
library;

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';

import 'province_sea_zone_detail_overlay_civilian_naval_sections.dart';
import 'province_sea_zone_detail_overlay_military_section.dart';
import 'province_sea_zone_detail_overlay_support.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/work_order_afford_preview_ui.dart';
import 'package:colonizethis_world/colonizethis_world.dart' show PlayerView;

/// Builds military, civilian, and naval sections when [showsFullIntel] is true;
/// otherwise returns obfuscated placeholders for each section.
({Widget military, Widget civilian, Widget naval})
buildProvinceContentUnitSections({
  required AppLocalizations l10n,
  required Game game,
  required bool showsFullIntel,
  required List<Unit> military,
  required List<Unit> civilian,
  required List<Fleet> fleetsInPort,
  required String humanPlayerId,
  required PlayerView playerView,
  required String provinceId,
  required Orders draftOrders,
  required int fortLevel,
  required bool showBuildFortActionIcon,
  required bool buildFortActionEnabled,
  required bool buildFortActionHasEngineerUnits,
  required String? selectedTileKey,
  VoidCallback? onBuildFortTap,
  required bool showMoveArmyControl,
  required bool moveArmyEnabled,
  required String moveArmyTooltip,
  VoidCallback? onMoveArmyTap,
  required bool showInvadeArmyControl,
  required bool invadeArmyEnabled,
  required String invadeArmyTooltip,
  VoidCallback? onInvadeArmyTap,
  String? provinceDisplayName,
}) {
  final militarySection = showsFullIntel
      ? buildMilitarySectionByOwner(
          l10n: l10n,
          game: game,
          military: military,
          humanPlayerId: humanPlayerId,
          provinceId: provinceId,
          draftOrders: draftOrders,
          fortLevel: fortLevel,
          showBuildFortActionIcon: showBuildFortActionIcon,
          buildFortActionEnabled: buildFortActionEnabled,
          buildFortActionHasEngineerUnits: buildFortActionHasEngineerUnits,
          buildFortTooltip: selectedTileKey == null
              ? l10n.provinceOverlay_tileBuildFortDisabledTooltip
              : provinceOverlayBuildFortTooltip(
                  l10n: l10n,
                  game: game,
                  humanPlayerId: humanPlayerId,
                  currentOrders: draftOrders,
                  selectedTileKey: selectedTileKey,
                  enabled: buildFortActionEnabled,
                  hasEngineerUnits: buildFortActionHasEngineerUnits,
                ),
          onBuildFortTap: onBuildFortTap,
          showMoveArmyControl: showMoveArmyControl,
          moveArmyEnabled: moveArmyEnabled,
          moveArmyTooltip: moveArmyTooltip,
          onMoveArmyTap: onMoveArmyTap,
          showInvadeArmyControl: showInvadeArmyControl,
          invadeArmyEnabled: invadeArmyEnabled,
          invadeArmyTooltip: invadeArmyTooltip,
          onInvadeArmyTap: onInvadeArmyTap,
          provinceDisplayName: provinceDisplayName,
        )
      : buildOverlaySection(
          l10n.provinceOverlay_sectionMilitary,
          overlayObfuscatedBodyText(l10n.provinceOverlay_unknown),
        );
  final civilianSection = showsFullIntel
      ? buildCivilianSectionFiltered(
          l10n: l10n,
          game: game,
          civilian: civilian,
          humanPlayerId: humanPlayerId,
          playerView: playerView,
          draftOrders: draftOrders,
        )
      : buildOverlaySection(
          l10n.provinceOverlay_sectionCivilian,
          overlayObfuscatedBodyText(l10n.provinceOverlay_unknown),
        );
  final naval = showsFullIntel
      ? buildNavalSection(
          l10n: l10n,
          game: game,
          fleets: fleetsInPort,
          humanPlayerId: humanPlayerId,
          draftOrders: draftOrders,
          pendingNavalPortProvinceId: provinceId,
        )
      : buildOverlaySection(
          l10n.provinceOverlay_sectionNaval,
          overlayObfuscatedBodyText(l10n.provinceOverlay_unknown),
        );
  return (
    military: militarySection,
    civilian: civilianSection,
    naval: naval,
  );
}
