/// Political section assembly and owner/region display helpers.
library;

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel_chrome_relation_badges.dart'
    show DiplomacyAllianceBadge;
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app/core/utils/faction_display_name.dart';

import 'province_sea_zone_detail_overlay_support.dart';
import 'package:colonizethis_world/colonizethis_world.dart'
    show WorldStateProvinceLookup, kRegionNewWorld, kRegionOldWorld;

String ownerNameForProvinceOverlay(
  AppLocalizations l10n,
  Game game,
  String? ownerId,
) {
  if (ownerId == null || ownerId.isEmpty) {
    return l10n.provinceOverlay_ownerUnclaimed;
  }
  return displayNameForFaction(game, ownerId);
}

@visibleForTesting
String provinceOverlayOwnerName(
  AppLocalizations l10n,
  Game game,
  String? ownerId,
) => ownerNameForProvinceOverlay(l10n, game, ownerId);

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
    kTownDevelopmentLevelMax => l10n.provinceOverlay_townDevelopmentGistMax,
    2 => l10n.provinceOverlay_townDevelopmentGistBonusActiveNextAt4,
    3 => l10n.provinceOverlay_townDevelopmentGistNextAt4,
    _ => l10n.provinceOverlay_townDevelopmentGistNextAt2,
  };
}

Widget buildPoliticalSection({
  required AppLocalizations l10n,
  required String name,
  required String ownerName,
  String? sightPhrase,
  required String regionLabel,
  required bool isCapital,
  required int townDevelopmentLevel,
  required bool showUpgradeTownControl,
  required bool upgradeTownEnabled,
  required String upgradeTownTooltip,
  VoidCallback? onUpgradeTownTap,
  required bool showEstablishConsulateControl,
  required bool establishConsulateEnabled,
  required bool establishConsulatePending,
  required String? establishConsulateRejectionReason,
  VoidCallback? onEstablishConsulateTap,
  bool showOwnerStanding = false,
  bool ownerStandingAtWar = false,
  bool showOwnerAllianceBadge = false,
  bool showOfferPeaceControl = false,
  bool offerPeaceEnabled = false,
  bool offerPeacePending = false,
  String? offerPeaceRejectionReason,
  VoidCallback? onOfferPeaceTap,
  required bool isNarrow,
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
        if (showOwnerStanding)
          ..._buildOwnerStandingLine(
            l10n: l10n,
            atWar: ownerStandingAtWar,
            showAllianceBadge: showOwnerAllianceBadge,
            bodyStyle: bodyStyle,
          ),
        if (showOfferPeaceControl)
          ..._buildOfferPeaceControl(
            l10n: l10n,
            enabled: offerPeaceEnabled,
            pending: offerPeacePending,
            rejectionReason: offerPeaceRejectionReason,
            onTap: onOfferPeaceTap,
            isNarrow: isNarrow,
            bodyStyle: gistStyle,
          ),
        if (sightPhrase != null)
          Text(l10n.provinceOverlay_sight(sightPhrase), style: bodyStyle),
        if (showEstablishConsulateControl)
          ..._buildEstablishConsulateControl(
            l10n: l10n,
            ownerName: ownerName,
            enabled: establishConsulateEnabled,
            pending: establishConsulatePending,
            rejectionReason: establishConsulateRejectionReason,
            onTap: onEstablishConsulateTap,
            isNarrow: isNarrow,
            bodyStyle: gistStyle,
          ),
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

List<Widget> _buildOwnerStandingLine({
  required AppLocalizations l10n,
  required bool atWar,
  required bool showAllianceBadge,
  required TextStyle bodyStyle,
}) {
  final standing = atWar
      ? l10n.provinceOverlay_ownerStandingAtWar
      : l10n.provinceOverlay_ownerStandingAtPeace;
  return [
    Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(standing, style: bodyStyle),
          if (showAllianceBadge) const DiplomacyAllianceBadge(),
        ],
      ),
    ),
  ];
}

List<Widget> _buildOfferPeaceControl({
  required AppLocalizations l10n,
  required bool enabled,
  required bool pending,
  required String? rejectionReason,
  required VoidCallback? onTap,
  required bool isNarrow,
  required TextStyle bodyStyle,
}) {
  final label = pending
      ? l10n.provinceOverlay_cancelOfferPeaceAction
      : l10n.provinceOverlay_offerPeaceAction;
  final tooltip = enabled || rejectionReason == null ? label : rejectionReason;
  return [
    Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          CtActionTextButton(
            label: label,
            tooltip: tooltip,
            semanticLabel: !enabled && rejectionReason != null
                ? l10n.provinceOverlay_offerPeaceDisabledSemantics(
                    rejectionReason,
                  )
                : label,
            enabled: enabled,
            onPressed: enabled ? onTap : null,
          ),
          if (isNarrow && !enabled && rejectionReason != null)
            Text(rejectionReason, style: bodyStyle),
        ],
      ),
    ),
  ];
}

List<Widget> _buildEstablishConsulateControl({
  required AppLocalizations l10n,
  required String ownerName,
  required bool enabled,
  required bool pending,
  required String? rejectionReason,
  required VoidCallback? onTap,
  required bool isNarrow,
  required TextStyle bodyStyle,
}) {
  final label = pending
      ? l10n.provinceOverlay_cancelEstablishConsulateAction
      : l10n.provinceOverlay_establishConsulateAction;
  final tooltip = enabled || rejectionReason == null ? label : rejectionReason;
  return [
    Text(l10n.provinceOverlay_noConsulateWith(ownerName), style: bodyStyle),
    Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          CtActionTextButton(
            label: label,
            tooltip: tooltip,
            semanticLabel: !enabled && rejectionReason != null
                ? l10n.provinceOverlay_establishConsulateDisabledSemantics(
                    rejectionReason,
                  )
                : label,
            enabled: enabled,
            onPressed: enabled ? onTap : null,
          ),
          if (isNarrow && !enabled && rejectionReason != null)
            Text(rejectionReason, style: bodyStyle),
        ],
      ),
    ),
  ];
}

Province? findProvinceForSeaZoneOverlay(Game game, String provinceId) =>
    game.worldState.allProvincesById[provinceId];
