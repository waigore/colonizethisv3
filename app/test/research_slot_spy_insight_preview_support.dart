// Fixtures for research-slot spy-insight preview tests (Refs #4305, #4457).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'panel_test_fixtures.dart';

const String kSpyInsightPreviewOw = 'oldWorld';
const String kSpyInsightPreviewFranceProvince = 'oldWorld|fr1';
const String kSpyInsightPreviewSpainProvince = 'oldWorld|es1';
const String kSpyInsightPreviewTechId = kTechIdCropRotation;

Player spyInsightPreviewPlayer({
  int treasury = 10000,
  Map<String, bool>? techUnlocked,
}) {
  return Player(
    id: 'gp1',
    displayName: 'England',
    isHuman: true,
    treasury: treasury,
    techUnlocked: techUnlocked,
  );
}

TechDefinition spyInsightPreviewTech() => const TechDefinition(
      id: kSpyInsightPreviewTechId,
      era: 1,
      category: 'civic',
      cost: 1800,
    );

Game spyInsightPreviewGame({required int rivalCount, bool rivalUnlocked = true}) {
  const human = Player(id: 'gp1', displayName: 'England', isHuman: true);
  final unlocked = rivalUnlocked ? const {kSpyInsightPreviewTechId: true} : null;
  final france = Player(
    id: 'gp2',
    displayName: 'France',
    isHuman: false,
    techUnlocked: unlocked,
  );
  final spain = Player(
    id: 'gp3',
    displayName: 'Spain',
    isHuman: false,
    techUnlocked: unlocked,
  );
  return buildPanelTestGame(
    id: 'spy-insight-preview',
    players: rivalCount >= 2 ? [human, france, spain] : [human, france],
    oldWorldProvinces: [
      const Province(
        id: kSpyInsightPreviewFranceProvince,
        regionId: kSpyInsightPreviewOw,
        ownerId: 'gp2',
      ),
      if (rivalCount >= 2)
        const Province(
          id: kSpyInsightPreviewSpainProvince,
          regionId: kSpyInsightPreviewOw,
          ownerId: 'gp3',
        ),
    ],
    oldWorldUnits: [
      Unit(
        id: 'spy_fr',
        type: kUnitTypeSpy,
        ownerId: human.id,
        locationProvinceId: kSpyInsightPreviewFranceProvince,
        tileKey: '$kSpyInsightPreviewFranceProvince|0|0',
      ),
      if (rivalCount >= 2)
        Unit(
          id: 'spy_es',
          type: kUnitTypeSpy,
          ownerId: human.id,
          locationProvinceId: kSpyInsightPreviewSpainProvince,
          tileKey: '$kSpyInsightPreviewSpainProvince|0|0',
        ),
    ],
  );
}
