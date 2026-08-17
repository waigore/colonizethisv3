import 'package:colonizethis_models/colonizethis_models.dart';

import 'debug_command_helpers_game.dart';
import 'debug_command_helpers_types.dart';

/// Apply-side spawn count cap. Must stay equal to parser
/// `kDebugConsoleMaxSpawnCount` in `colonizethis_debug_console` (Refs #4484).
/// Do not import that package from here — document drift in SPEC only.
const int kDebugSpawnCountCap = 25;

/// Clamps [count] to [kDebugSpawnCountCap]. Spawn handlers must call this
/// instead of inlining a raw `25` clamp (enforced by
/// `repo.app_debug_handler_guard_helpers`).
int boundDebugSpawnCount(int count) =>
    count > kDebugSpawnCountCap ? kDebugSpawnCountCap : count;

/// Shared unsupported-catalog reject for spawn apply handlers.
DebugCommandResult debugUnsupportedSpawnType({
  required String typeLabel,
  required String typeId,
}) => (
  game: null,
  message: 'Debug spawn ignored: unsupported $typeLabel type $typeId.',
);

/// Mints [count] canonical land-unit ids from the current world unit bags.
List<String> mintDebugLandUnitIds({
  required WorldState worldState,
  required int count,
}) {
  final allUnits = <Unit>[
    ...worldState.oldWorld.units,
    ...worldState.newWorld.units,
  ];
  final usedUnitIds = {for (final unit in allUnits) unit.id};
  var nextUnitSeq = nextCanonicalUnitSequence(units: allUnits);
  final ids = <String>[];
  for (var i = 0; i < count; i++) {
    final unitId = mintCanonicalUnitId(
      usedUnitIds: usedUnitIds,
      nextSequence: nextUnitSeq,
    );
    nextUnitSeq++;
    ids.add(unitId);
  }
  return ids;
}
