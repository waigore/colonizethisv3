// Scenario run tear-offs for explorer consulate gate predicate (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
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
