import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_combat/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'combat_effective_strength.dart';
import 'conflict_detection.dart';

part 'quick_battle_resolver_engine.dart';
part 'quick_battle_resolver_outcome.dart';

/// Quick Battle resolution pipeline. SPEC/program/quick-battle-resolution.md.
/// Deterministic for given seed; output feeds same casualty/flip pipeline as auto-resolve.
///
/// ## Siege — defender damage split (virtual emplaced guns)
///
/// When [QuickBattleInput.emplacedGuns] is non-empty, the aggregate emplaced lump
/// (`fortGunCount × fortEmplacedStrength`) is **not** applied (no double-count).
///
/// Each round, after computing [defLossFraction] from the strength ratio, defender
/// losses are split:
/// - **Gun HP:** `gunHpLoss = min(sumAliveGunHp, max(0, round(defLossFraction * sumAliveGunHp)))`.
///   Each point removes 1 HP from virtual guns in **round-robin** over guns sorted by [QuickBattleEmplacedGun.id].
/// - **Regiments:** `regFrac = regimentCount > 0 ? (defLossFraction * regimentCount / (sumAliveGunHp + regimentCount)).clamp(0, 1) : 0`,
///   then `_pickCasualties(defGroups, regFrac, rng)`.
///
/// Determinism: RNG order is unchanged for a given seed (CP rolls and shuffles happen in the same
/// sequence as before; gun damage uses no extra randomness).

/// Resolves a Quick Battle to completion. Uses [roundActions] if provided; otherwise
/// applies default deterministic actions (Volley Fire each round) for AI/simulation.
QuickBattleResult resolveQuickBattle(
  QuickBattleInput input, {
  List<QuickBattleRoundActions>? roundActions,
}) {
  combatLog.d(
    'quick_battle start province=${input.provinceId} '
    'seed=${input.seed} rounds=${input.maxRounds}',
  );
  final rng = Random(input.seed);
  var attGroups = _copyGroups(input.attackerDeployment.groups);
  var defGroups = _copyGroups(input.defenderDeployment.groups);
  final attCasualties = <String>[];
  final defCasualties = <String>[];
  final useVirtualEmplaced = input.emplacedGuns.isNotEmpty;
  final mutableGuns = useVirtualEmplaced
      ? input.emplacedGuns
            .map(
              (g) => _MutableEmplacedGun(
                id: g.id,
                maxHp: g.maxHp,
                hp: g.hp,
                attackStrength: g.attackStrength,
                defenseStrength: g.defenseStrength,
              ),
            )
            .toList()
      : <_MutableEmplacedGun>[];

  for (var round = 1; round <= input.maxRounds; round++) {
    final attCp = _rollCommandPoints(rng);
    final defCp = _rollCommandPoints(rng);

    final rActions = roundActions != null && round <= roundActions.length
        ? roundActions[round - 1]
        : null;
    final rawAttActs =
        rActions?.attackerActions ??
        rActions?.actions ??
        const [QuickBattleAction.volleyFire];
    final rawDefActs =
        rActions?.defenderActions ??
        rActions?.actions ??
        const [QuickBattleAction.volleyFire];

    final attActs = _limitActionsByCp(rawAttActs, attCp);
    final defActs = _limitActionsByCp(rawDefActs, defCp);

    final attMods = _aggregateActionModifiers(attActs);
    final defMods = _aggregateActionModifiers(defActs);

    final attackerActsFirst = _attackerActsFirst(input);
    // Compute round-level effective strengths once. Each strike only mutates
    // one side's state, so the unchanged side's strength stays valid across
    // both strikes within this round.
    var effAtt = _attackerEffectiveStrength(
      input: input,
      attGroups: attGroups,
      attMods: attMods,
    );
    var effDef = _defenderEffectiveStrength(
      input: input,
      defGroups: defGroups,
      defMods: defMods,
      mutableGuns: mutableGuns,
      useVirtualEmplaced: useVirtualEmplaced,
    );
    final List<String> defLoss;
    final List<String> attLoss;
    if (attackerActsFirst) {
      final defLossFraction = _defenderLossFractionFromAttackerStrike(
        input: input,
        effAtt: effAtt,
        effDef: effDef,
        attMods: attMods,
        defMods: defMods,
      );
      defLoss = _pickDefenderLosses(
        groups: defGroups,
        fraction: defLossFraction,
        rng: rng,
        mutableGuns: mutableGuns,
        useVirtualEmplaced: useVirtualEmplaced,
      );
      defCasualties.addAll(defLoss);
      defGroups = _removeCasualties(defGroups, defLoss);

      if (_totalUnitCount(defGroups) <= 0) {
        return _finishAndLogQuickBattleResult(
          winner: QuickBattleWinner.attacker,
          attackerCasualties: attCasualties,
          defenderCasualties: defCasualties,
          provinceFlips: true,
          input: input,
          mutableGuns: mutableGuns,
          useVirtualEmplaced: useVirtualEmplaced,
        );
      }

      // Defender state changed (regiments removed, gun HP possibly damaged).
      // Recompute defender strength only; attacker strength is unchanged.
      effDef = _defenderEffectiveStrength(
        input: input,
        defGroups: defGroups,
        defMods: defMods,
        mutableGuns: mutableGuns,
        useVirtualEmplaced: useVirtualEmplaced,
      );
      final attLossFraction = _attackerLossFractionFromDefenderStrike(
        effAtt: effAtt,
        effDef: effDef,
        attMods: attMods,
        defMods: defMods,
      );
      attLoss = _pickCasualties(attGroups, attLossFraction, rng);
      attCasualties.addAll(attLoss);
      attGroups = _removeCasualties(attGroups, attLoss);
    } else {
      final attLossFraction = _attackerLossFractionFromDefenderStrike(
        effAtt: effAtt,
        effDef: effDef,
        attMods: attMods,
        defMods: defMods,
      );
      attLoss = _pickCasualties(attGroups, attLossFraction, rng);
      attCasualties.addAll(attLoss);
      attGroups = _removeCasualties(attGroups, attLoss);

      if (_totalUnitCount(attGroups) <= 0) {
        return _finishAndLogQuickBattleResult(
          winner: QuickBattleWinner.defender,
          attackerCasualties: attCasualties,
          defenderCasualties: defCasualties,
          provinceFlips: false,
          input: input,
          mutableGuns: mutableGuns,
          useVirtualEmplaced: useVirtualEmplaced,
        );
      }

      // Attacker state changed; recompute attacker strength only. Defender
      // groups and gun HP are unchanged so effDef remains valid.
      effAtt = _attackerEffectiveStrength(
        input: input,
        attGroups: attGroups,
        attMods: attMods,
      );
      final defLossFraction = _defenderLossFractionFromAttackerStrike(
        input: input,
        effAtt: effAtt,
        effDef: effDef,
        attMods: attMods,
        defMods: defMods,
      );
      defLoss = _pickDefenderLosses(
        groups: defGroups,
        fraction: defLossFraction,
        rng: rng,
        mutableGuns: mutableGuns,
        useVirtualEmplaced: useVirtualEmplaced,
      );
      defCasualties.addAll(defLoss);
      defGroups = _removeCasualties(defGroups, defLoss);
    }

    if (defLoss.length > attLoss.length && defLoss.isNotEmpty) {
      defGroups = _degradeCohesion(defGroups);
    } else if (attLoss.length > defLoss.length && attLoss.isNotEmpty) {
      attGroups = _degradeCohesion(attGroups);
    }

    if (_totalUnitCount(defGroups) <= 0) {
      return _finishAndLogQuickBattleResult(
        winner: QuickBattleWinner.attacker,
        attackerCasualties: attCasualties,
        defenderCasualties: defCasualties,
        provinceFlips: true,
        input: input,
        mutableGuns: mutableGuns,
        useVirtualEmplaced: useVirtualEmplaced,
      );
    }
    if (_totalUnitCount(attGroups) <= 0) {
      return _finishAndLogQuickBattleResult(
        winner: QuickBattleWinner.defender,
        attackerCasualties: attCasualties,
        defenderCasualties: defCasualties,
        provinceFlips: false,
        input: input,
        mutableGuns: mutableGuns,
        useVirtualEmplaced: useVirtualEmplaced,
      );
    }
  }

  return _resolveQuickBattleRoundLimitOutcome(
    input: input,
    attGroups: attGroups,
    defGroups: defGroups,
    attackerCasualties: attCasualties,
    defenderCasualties: defCasualties,
    mutableGuns: mutableGuns,
    useVirtualEmplaced: useVirtualEmplaced,
  );
}

QuickBattleResult _resolveQuickBattleRoundLimitOutcome({
  required QuickBattleInput input,
  required List<QuickBattleGroup> attGroups,
  required List<QuickBattleGroup> defGroups,
  required List<String> attackerCasualties,
  required List<String> defenderCasualties,
  required List<_MutableEmplacedGun> mutableGuns,
  required bool useVirtualEmplaced,
}) {
  final finalAttStr =
      _effectiveStrength(attGroups, input.attackerDeployment.laneTerrain) *
      input.attackerLeaderMultiplier;
  final finalDefStr =
      _effectiveStrength(defGroups, input.defenderDeployment.laneTerrain) *
          input.defenderLeaderMultiplier +
      (useVirtualEmplaced ? _aliveGunStrengthSum(mutableGuns) : 0.0);

  if (finalAttStr > finalDefStr * 1.2) {
    return _finishAndLogQuickBattleResult(
      winner: QuickBattleWinner.attacker,
      attackerCasualties: attackerCasualties,
      defenderCasualties: defenderCasualties,
      provinceFlips: true,
      input: input,
      mutableGuns: mutableGuns,
      useVirtualEmplaced: useVirtualEmplaced,
    );
  }
  if (finalDefStr > finalAttStr * 1.2) {
    return _finishAndLogQuickBattleResult(
      winner: QuickBattleWinner.defender,
      attackerCasualties: attackerCasualties,
      defenderCasualties: defenderCasualties,
      provinceFlips: false,
      input: input,
      mutableGuns: mutableGuns,
      useVirtualEmplaced: useVirtualEmplaced,
    );
  }
  return _finishAndLogQuickBattleResult(
    winner: QuickBattleWinner.mutualExhaustion,
    attackerCasualties: attackerCasualties,
    defenderCasualties: defenderCasualties,
    provinceFlips: false,
    input: input,
    mutableGuns: mutableGuns,
    useVirtualEmplaced: useVirtualEmplaced,
  );
}

/// Applies QuickBattleResult to Game: remove casualties, flip province if winner is attacker.
Game applyQuickBattleResultToGame(
  Game game,
  BattleContext ctx,
  QuickBattleResult result,
) {
  final region = game.worldState.regionDataForIdOrThrow(ctx.regionId);
  final casualtySet = {
    ...result.attackerCasualties,
    ...result.defenderCasualties,
  };
  final survivingUnits = region.units
      .where((u) => !casualtySet.contains(u.id))
      .toList();

  var provinces = region.provinces;
  if (result.fortDowngradeFromDestroyedEmplaced) {
    provinces = decrementFortLevelForProvinceIdIfPresent(
      provinces,
      ctx.provinceId,
    );
  }

  final newRegion = RegionData(provinces: provinces, units: survivingUnits);
  final newWorldState = game.worldState.updateRegionById(
    ctx.regionId,
    (_) => newRegion,
  );

  var updatedGame = game.withWorldState(newWorldState);

  if (result.provinceFlips &&
      result.winner == QuickBattleWinner.attacker &&
      ctx.attackers.isNotEmpty) {
    final attackerFactionId = ctx.attackers.first.factionId;
    final row = resolveProvinceRowForOwnershipTransfer(
      game.worldState,
      ctx.provinceId,
    );
    final oldOwnerId = row?.province.ownerId ?? ctx.defenderFactionId;
    updatedGame = applyCanonicalSingleProvinceOwnershipTransfer(
      updatedGame,
      targetProvinceId: ctx.provinceId,
      oldOwnerId: oldOwnerId,
      newOwnerId: attackerFactionId,
    );
  }

  updatedGame = updatedGame.copyWith(
    worldState: reconcileArmiesAfterUnitsChanged(
      updatedGame.worldState,
      updatedGame,
    ),
  );
  return updatedGame;
}
