import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  const humanId = 'gp1';
  const minorId = 'minor1';
  const tileKey = 'newWorld|p1|0,0';

  Game baseGame({
    List<OvertureState> overtureStates = const [],
    Map<String, String>? purchasedTilesByTileKey,
    Map<String, Map<String, List<String>>> tileKeysByRegionAndProvince = const {
      'newWorld': {
        'newWorld|p1': [tileKey],
      },
    },
  }) =>
      diplomacyGame(
        players: const [
          Player(id: humanId, displayName: 'England', isHuman: true),
        ],
        minorNations: const [MinorNation(id: minorId, displayName: 'Bavaria')],
        newWorld: RegionData(
          provinces: [
            Province(id: 'newWorld|p1', regionId: 'newWorld', ownerId: minorId),
          ],
        ),
        overtureStates: overtureStates,
        purchasedTilesByTileKey: purchasedTilesByTileKey,
        tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
      );

  test('embassy-only stake is detected', () {
    final flags = interventionHoldFlags(
      game: baseGame(
        overtureStates: const [
          OvertureState(
            gpId: humanId,
            targetId: minorId,
            stage: OvertureStage.embassy,
          ),
        ],
      ),
      interveningGpId: humanId,
      defenderMinorOrTribeId: minorId,
    );
    expect(flags.hasEmbassy, isTrue);
    expect(flags.hasPurchasedLand, isFalse);
    expect(flags.isEmpty, isFalse);
  });

  test('purchased-land-only stake is detected', () {
    final flags = interventionHoldFlags(
      game: baseGame(
        purchasedTilesByTileKey: const {tileKey: humanId},
      ),
      interveningGpId: humanId,
      defenderMinorOrTribeId: minorId,
    );
    expect(flags.hasEmbassy, isFalse);
    expect(flags.hasPurchasedLand, isTrue);
    expect(flags.isEmpty, isFalse);
  });

  test('both embassy and purchased land are detected', () {
    final flags = interventionHoldFlags(
      game: baseGame(
        overtureStates: const [
          OvertureState(
            gpId: humanId,
            targetId: minorId,
            stage: OvertureStage.embassy,
          ),
        ],
        purchasedTilesByTileKey: const {tileKey: humanId},
      ),
      interveningGpId: humanId,
      defenderMinorOrTribeId: minorId,
    );
    expect(flags.hasEmbassy, isTrue);
    expect(flags.hasPurchasedLand, isTrue);
  });

  test('no stake yields empty flags', () {
    final flags = interventionHoldFlags(
      game: baseGame(),
      interveningGpId: humanId,
      defenderMinorOrTribeId: minorId,
    );
    expect(flags.isEmpty, isTrue);
  });
}
