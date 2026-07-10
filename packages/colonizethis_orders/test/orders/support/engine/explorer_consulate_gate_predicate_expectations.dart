// Compact explorer Consulate-gate predicate assertions (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'explorer_consulate_gate_predicate_fixtures.dart';

/// Pins for [explorerConsulateGatePredicateScenarios] rows.
enum ExplorerConsulateGatePredicateTarget {
  blocksMinorTribeWhenNoOverture,
  blocksWhenOvertureBelowConsulate,
  doesNotBlockWhenConsulateHeld,
  doesNotBlockWhenEmbassyHeld,
  doesNotGateGpOwnedProvince,
  doesNotGateOwnProvinceOrNullOwner,
}

void runExplorerConsulateGatePredicateExpectation(
  ExplorerConsulateGatePredicateTarget target,
) {
  switch (target) {
    case ExplorerConsulateGatePredicateTarget.blocksMinorTribeWhenNoOverture:
      expect(
        explorerConsulateGateBlocksMinorTribeProvince(
          game: ecgGameWith(),
          playerId: ecgPlayerId,
          provinceOwnerId: 'tribe1',
        ),
        isTrue,
      );

    case ExplorerConsulateGatePredicateTarget.blocksWhenOvertureBelowConsulate:
      expect(
        explorerConsulateGateBlocksMinorTribeProvince(
          game: ecgGameWith(
            overtures: const [
              OvertureState(
                gpId: ecgPlayerId,
                targetId: 'tribe1',
                stage: OvertureStage.none,
              ),
            ],
          ),
          playerId: ecgPlayerId,
          provinceOwnerId: 'tribe1',
        ),
        isTrue,
      );

    case ExplorerConsulateGatePredicateTarget.doesNotBlockWhenConsulateHeld:
      expect(
        explorerConsulateGateBlocksMinorTribeProvince(
          game: ecgGameWith(
            overtures: const [
              OvertureState(
                gpId: ecgPlayerId,
                targetId: 'tribe1',
                stage: OvertureStage.tradeConsulate,
              ),
            ],
          ),
          playerId: ecgPlayerId,
          provinceOwnerId: 'tribe1',
        ),
        isFalse,
      );

    case ExplorerConsulateGatePredicateTarget.doesNotBlockWhenEmbassyHeld:
      expect(
        explorerConsulateGateBlocksMinorTribeProvince(
          game: ecgGameWith(
            overtures: const [
              OvertureState(
                gpId: ecgPlayerId,
                targetId: 'tribe1',
                stage: OvertureStage.embassy,
              ),
            ],
          ),
          playerId: ecgPlayerId,
          provinceOwnerId: 'tribe1',
        ),
        isFalse,
      );

    case ExplorerConsulateGatePredicateTarget.doesNotGateGpOwnedProvince:
      expect(
        explorerConsulateGateBlocksMinorTribeProvince(
          game: ecgGameWith(),
          playerId: ecgPlayerId,
          provinceOwnerId: 'gp2',
        ),
        isFalse,
      );

    case ExplorerConsulateGatePredicateTarget.doesNotGateOwnProvinceOrNullOwner:
      final game = ecgGameWith();
      expect(
        explorerConsulateGateBlocksMinorTribeProvince(
          game: game,
          playerId: ecgPlayerId,
          provinceOwnerId: ecgPlayerId,
        ),
        isFalse,
      );
      expect(
        explorerConsulateGateBlocksMinorTribeProvince(
          game: game,
          playerId: ecgPlayerId,
          provinceOwnerId: null,
        ),
        isFalse,
      );
  }
}
