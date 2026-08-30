// Shared Counsel Military tab fixtures and golden hosts (Refs #4307).

import 'package:colonizethis_app/features/game/screens/counsel/counsel_military_tab_body.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_logic/industry_counsel_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'panel_fixtures/train.dart';

const Size kCounselMilitaryPanelGoldenViewport = Size(360, 720);

MilitaryCounselRecommendation counselTestMilitaryTrainRecommendation({
  String unitType = 'peasant_levies',
  int count = 2,
  bool isHighlight = true,
}) {
  return MilitaryCounselRecommendation(
    recommendationId: 'train:$unitType',
    kind: MilitaryCounselRecommendationKind.trainUnit,
    rankScore: 10,
    briefReasonKey: MilitaryCounselReasonKey.affordableTrain,
    detailReasonKeys: const [MilitaryCounselReasonKey.affordableTrain],
    isHighlight: isHighlight,
    unitType: unitType,
    count: count,
    costSnapshot: const MilitaryCounselBuildCostSnapshot(
      treasuryCost: 10,
      materialCosts: {},
      peasantCost: 1,
    ),
  );
}

MilitaryCounselRecommendation counselTestMilitaryInvadeRecommendation({
  String armyId = 'army1',
  String destinationProvinceId = 'oldWorld|p2',
  String destinationProvinceLabel = 'Border Province',
  String ownerFactionId = 'gp2',
  bool requiresDeclareWar = true,
  bool isHighlight = true,
}) {
  return MilitaryCounselRecommendation(
    recommendationId: 'invade:$armyId:$destinationProvinceId',
    kind: MilitaryCounselRecommendationKind.invade,
    rankScore: 5,
    briefReasonKey: requiresDeclareWar
        ? MilitaryCounselReasonKey.declareWarInvasion
        : MilitaryCounselReasonKey.atWarInvasion,
    detailReasonKeys: [
      requiresDeclareWar
          ? MilitaryCounselReasonKey.declareWarInvasion
          : MilitaryCounselReasonKey.atWarInvasion,
    ],
    isHighlight: isHighlight,
    armyId: armyId,
    destinationProvinceId: destinationProvinceId,
    destinationProvinceLabel: destinationProvinceLabel,
    ownerFactionId: ownerFactionId,
    requiresDeclareWar: requiresDeclareWar,
    invasionIntel: const MilitaryCounselInvasionIntelSummary(
      intelLevel: MilitaryCounselInvasionIntelLevel.unknown,
    ),
  );
}

List<MilitaryCounselRecommendation> counselTestDefaultMilitaryRecommendations() {
  return [
    counselTestMilitaryTrainRecommendation(),
    counselTestMilitaryInvadeRecommendation(),
    counselTestMilitaryInvadeRecommendation(
      armyId: 'army2',
      destinationProvinceId: 'oldWorld|p3',
      destinationProvinceLabel: 'Second Front',
      ownerFactionId: 'gp3',
      isHighlight: false,
    ),
  ];
}

/// Mirrors the Military tab column inside [CounselScreen] for golden captures.
Widget counselMilitaryTabGoldenHost({
  required List<MilitaryCounselRecommendation> recommendations,
  String? highlightRecommendationId,
  bool canEdit = true,
  CounselMilitaryCallbacks callbacks = const CounselMilitaryCallbacks(),
  Size viewport = kCounselMilitaryPanelGoldenViewport,
  Game? game,
}) {
  final l10n = lookupAppLocalizations(const Locale('en'));
  final hostGame = game ?? buildTrainPanelTestGame();
  return SizedBox(
    width: viewport.width,
    height: viewport.height,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Text(
            l10n.militaryCounsel_tabMilitary,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: CounselMilitaryTabBody(
            game: hostGame,
            recommendations: recommendations,
            highlightRecommendationId: highlightRecommendationId,
            l10n: l10n,
            canEdit: canEdit,
            callbacks: callbacks,
          ),
        ),
      ],
    ),
  );
}
