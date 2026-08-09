import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'diplomacy_relation_lookup.dart';
import 'diplomacy_shared_helpers.dart';
import 'faction_absorption_apply.dart';

/// Join-Empire absorption shared between minor/tribe and GP targets.
/// SPEC/game/diplomacy.md. Refs #2071.
abstract final class FactionAbsorptionEngine {
  FactionAbsorptionEngine._();

  /// Transfers all provinces, units, and fleets owned by [targetId] to [gpId],
  /// deducts Join Empire cost from GP treasury, removes the Minor/Tribe and
  /// cleans overtures/relations.
  static Game absorbMinorOrTribeIntoGp(
    Game game,
    String gpId,
    String targetId,
    int turn,
  ) {
    return absorbFactionIntoGp(
      game,
      gpId: gpId,
      absorbedFactionId: targetId,
      kind: FactionAbsorptionKind.minorOrTribe,
    );
  }

  /// Absorbs a nearly-defeated GP [targetGpId] into [gpId] (player removed).
  static Game absorbGreatPowerIntoGp(
    Game game,
    String gpId,
    String targetGpId,
  ) {
    return absorbFactionIntoGp(
      game,
      gpId: gpId,
      absorbedFactionId: targetGpId,
      kind: FactionAbsorptionKind.greatPower,
    );
  }

  /// Marks Tribe [tribeId] as a colony of [gpId] via Tribe Join Empire.
  ///
  /// Unlike [absorbMinorOrTribeIntoGp], the Tribe is **not** absorbed: it stays
  /// in [Game.tribes], its provinces/units/fleets are not transferred, and its
  /// overtures/relations are preserved. Only the Join Empire cost is deducted
  /// from the GP treasury and a [ColonyState] is recorded (one per Tribe; an
  /// existing colony record for the same Tribe is replaced).
  /// SPEC/game/diplomacy.md § GP–Minor/Tribe Rules (Join Empire → colony).
  static Game markTribeAsColony(
    Game game,
    String gpId,
    String tribeId,
    int turn,
  ) {
    final cost = joinEmpireCostForMinorOrTribe(game, tribeId);
    var players = List<Player>.from(game.players);
    final gpIdx = indexByKey(players, (p) => p.id)[gpId] ?? -1;
    players = debitPlayerTreasury(players, gpIdx, cost);

    final colonies = game.colonyStates
        .where((c) => c.tribeId != tribeId)
        .toList()
      ..add(
        ColonyState(tribeId: tribeId, colonyOfGpId: gpId, sinceTurn: turn),
      );

    return game.withPlayers(players).copyWith(colonyStates: colonies);
  }
}
