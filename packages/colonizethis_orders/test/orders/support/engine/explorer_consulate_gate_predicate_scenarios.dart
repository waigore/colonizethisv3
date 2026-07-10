// Table-driven explorer Consulate-gate predicate scenarios (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';
import 'explorer_consulate_gate_predicate_fixtures.dart';

void ecgpRunBlocksMinorTribeWhenNoOverture() {
  expect(
    explorerConsulateGateBlocksMinorTribeProvince(
      game: ecgGameWith(),
      playerId: ecgPlayerId,
      provinceOwnerId: 'tribe1',
    ),
    isTrue,
  );
}

void ecgpRunBlocksWhenOvertureBelowConsulate() {
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
}

void ecgpRunDoesNotBlockWhenConsulateHeld() {
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
}

void ecgpRunDoesNotBlockWhenEmbassyHeld() {
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
}

void ecgpRunDoesNotGateGpOwnedProvince() {
  expect(
    explorerConsulateGateBlocksMinorTribeProvince(
      game: ecgGameWith(),
      playerId: ecgPlayerId,
      provinceOwnerId: 'gp2',
    ),
    isFalse,
  );
}

void ecgpRunDoesNotGateOwnProvinceOrNullOwner() {
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

/// Canonical scenarios for explorer_consulate_gate_predicate family tests.
List<RunnableScenario> explorerConsulateGatePredicateScenarios() => const [
  rs('blocks a Minor/Tribe province when no overture exists', ecgpRunBlocksMinorTribeWhenNoOverture, '#3753 R4'),
  rs('blocks when the overture is below Consulate (none)', ecgpRunBlocksWhenOvertureBelowConsulate, '#3753 R4'),
  rs('does not block when a Consulate is held', ecgpRunDoesNotBlockWhenConsulateHeld, '#3753 R4'),
  rs('does not block when an Embassy (above Consulate) is held', ecgpRunDoesNotBlockWhenEmbassyHeld, '#3753 R4b'),
  rs('does not gate a Great Power-owned province', ecgpRunDoesNotGateGpOwnedProvince, '#3753 R4'),
  rs('does not gate the player own province or a null owner', ecgpRunDoesNotGateOwnProvinceOrNullOwner, '#3753 R4'),
];
