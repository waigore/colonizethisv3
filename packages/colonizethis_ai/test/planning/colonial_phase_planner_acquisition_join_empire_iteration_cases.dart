// Join-Empire iteration / determinism cases for `planColonialAcquisition`.
// Refs #2509 S3; registered from `colonial_phase_planner_acquisition_join_empire_tail_cases.dart`.

import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/colonial_acquisition_test_support.dart';

const String _gp1 = kColonialPhaseGp1;
const String _tribe1 = kColonialPhaseTribe1;
const String _tribe2 = kColonialPhaseTribe2;

const String _province1 = kColonialAcquisitionNwProv1;
const String _province2 = kColonialAcquisitionNwProv2;

void registerColonialPhasePlannerAcquisitionJoinEmpireCasesIteration() {
  group('planColonialAcquisition (Join Empire path)', () {
    test('two valid tribe targets -> first sorted invadable NW wins', () {
      final game = buildColonialAcquisitionGame(
        gameIdPrefix: 'g-2509-colonial-acquisition',
        minorNations: kColonialAcquisitionDefaultMinors,
        newWorldProvinces: const [
          Province(id: _province1, regionId: 'newWorld', ownerId: _tribe1),
          Province(id: _province2, regionId: 'newWorld', ownerId: _tribe2),
        ],
        overtureStates: <OvertureState>[
          colonialAcquisitionNap(_gp1, _tribe1),
          colonialAcquisitionNap(_gp1, _tribe2),
        ],
        diplomacyRelations: <DiplomacyRelation>[
          colonialAcquisitionFriendly(_gp1, _tribe1),
          colonialAcquisitionFriendly(_gp1, _tribe2),
        ],
      );
      final snapshot = buildColonialAcquisitionSnapshot(
        invadableNw: const [_province1, _province2],
      );
      expect(
        planColonialAcquisition(game: game, snapshot: snapshot),
        const ColonialAcquisitionTarget(
          targetFactionId: _tribe1,
          method: AcquisitionMethod.joinEmpire,
        ),
        reason:
            'Iteration over `invadableNewWorldProvinceIdsSorted` is '
            'ascending; the first satisfying province (tribe1) wins '
            'the deterministic tie-break (Refs #2509 Must-have #7).',
      );
    });

    test('second sorted tribe wins when first sorted tribe fails a gate', () {
      final game = buildColonialAcquisitionGame(
        gameIdPrefix: 'g-2509-colonial-acquisition',
        minorNations: kColonialAcquisitionDefaultMinors,
        newWorldProvinces: const [
          Province(id: _province1, regionId: 'newWorld', ownerId: _tribe1),
          Province(id: _province2, regionId: 'newWorld', ownerId: _tribe2),
        ],
        overtureStates: <OvertureState>[
          colonialAcquisitionEmbassy(_gp1, _tribe1),
          colonialAcquisitionNap(_gp1, _tribe2),
        ],
        diplomacyRelations: <DiplomacyRelation>[
          colonialAcquisitionFriendly(_gp1, _tribe1),
          colonialAcquisitionFriendly(_gp1, _tribe2),
        ],
      );
      final snapshot = buildColonialAcquisitionSnapshot(
        invadableNw: const [_province1, _province2],
      );
      expect(
        planColonialAcquisition(game: game, snapshot: snapshot),
        const ColonialAcquisitionTarget(
          targetFactionId: _tribe2,
          method: AcquisitionMethod.joinEmpire,
        ),
        reason:
            'tribe1 fails the nap gate (overture at embassy) so the '
            'iteration falls through to tribe2 whose overture is at '
            'nap. The second-sorted province wins when the first '
            'fails a gate.',
      );
    });

    test('determinism: identical inputs produce identical targets', () {
      final game = buildColonialAcquisitionGame(
        gameIdPrefix: 'g-2509-colonial-acquisition',
        minorNations: kColonialAcquisitionDefaultMinors,
        newWorldProvinces: const [
          Province(id: _province1, regionId: 'newWorld', ownerId: _tribe1),
          Province(id: _province2, regionId: 'newWorld', ownerId: _tribe2),
        ],
        overtureStates: <OvertureState>[
          colonialAcquisitionNap(_gp1, _tribe1),
          colonialAcquisitionNap(_gp1, _tribe2),
        ],
        diplomacyRelations: <DiplomacyRelation>[
          colonialAcquisitionFriendly(_gp1, _tribe1),
          colonialAcquisitionFriendly(_gp1, _tribe2),
        ],
      );
      final snapshot = buildColonialAcquisitionSnapshot(
        invadableNw: const [_province1, _province2],
      );
      final first = planColonialAcquisition(game: game, snapshot: snapshot);
      final second = planColonialAcquisition(game: game, snapshot: snapshot);
      expect(second, first);
      expect(
        first,
        isNotNull,
        reason: 'Determinism test must run on a satisfying input.',
      );
    });
  });
}
