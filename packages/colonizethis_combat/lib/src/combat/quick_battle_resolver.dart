import 'dart:math';

import 'package:colonizethis_combat/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'conflict_detection.dart';
import 'quick_battle_action_modifiers.dart';
import 'quick_battle_emplaced_guns.dart';
import 'quick_battle_resolver_engine.dart';
import 'quick_battle_resolver_outcome.dart';

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
///   then `pickCasualties(defGroups, regFrac, rng)`.
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
  var attGroups = copyGroups(input.attackerDeployment.groups);
  var defGroups = copyGroups(input.defenderDeployment.groups);
  final attCasualties = <String>[];
  final defCasualties = <String>[];
  final useVirtualEmplaced = input.emplacedGuns.isNotEmpty;
  final mutableGuns = useVirtualEmplaced
      ? input.emplacedGuns.map(MutableEmplacedGun.fromInput).toList()
      : <MutableEmplacedGun>[];
  final finisher = QuickBattleFinisher(
    input: input,
    attackerCasualties: attCasualties,
    defenderCasualties: defCasualties,
    mutableGuns: mutableGuns,
    useVirtualEmplaced: useVirtualEmplaced,
  );

  for (var round = 1; round <= input.maxRounds; round++) {
    final attCp = rollCommandPoints(rng);
    final defCp = rollCommandPoints(rng);

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

    final attActs = limitActionsByCp(rawAttActs, attCp);
    final defActs = limitActionsByCp(rawDefActs, defCp);

    final attMods = aggregateActionModifiers(attActs);
    final defMods = aggregateActionModifiers(defActs);

    final actsFirst = attackerActsFirst(input);
    // Compute round-level effective strengths once. Each strike only mutates
    // one side's state, so the unchanged side's strength stays valid across
    // both strikes within this round.
    var effAtt = attackerEffectiveStrength(
      input: input,
      attGroups: attGroups,
      attMods: attMods,
    );
    var effDef = defenderEffectiveStrength(
      input: input,
      defGroups: defGroups,
      defMods: defMods,
      mutableGuns: mutableGuns,
      useVirtualEmplaced: useVirtualEmplaced,
    );
    final List<String> defLoss;
    final List<String> attLoss;
    if (actsFirst) {
      final defLossFraction = defenderLossFractionFromAttackerStrike(
        input: input,
        effAtt: effAtt,
        effDef: effDef,
        attMods: attMods,
        defMods: defMods,
      );
      defLoss = pickDefenderLosses(
        groups: defGroups,
        fraction: defLossFraction,
        rng: rng,
        mutableGuns: mutableGuns,
        useVirtualEmplaced: useVirtualEmplaced,
      );
      defCasualties.addAll(defLoss);
      defGroups = removeCasualties(defGroups, defLoss);

      if (totalUnitCount(defGroups) <= 0) {
        return finisher.finish(
          winner: QuickBattleWinner.attacker,
          provinceFlips: true,
        );
      }

      // Defender state changed (regiments removed, gun HP possibly damaged).
      // Recompute defender strength only; attacker strength is unchanged.
      effDef = defenderEffectiveStrength(
        input: input,
        defGroups: defGroups,
        defMods: defMods,
        mutableGuns: mutableGuns,
        useVirtualEmplaced: useVirtualEmplaced,
      );
      final attLossFraction = attackerLossFractionFromDefenderStrike(
        effAtt: effAtt,
        effDef: effDef,
        attMods: attMods,
        defMods: defMods,
      );
      attLoss = pickCasualties(attGroups, attLossFraction, rng);
      attCasualties.addAll(attLoss);
      attGroups = removeCasualties(attGroups, attLoss);
    } else {
      final attLossFraction = attackerLossFractionFromDefenderStrike(
        effAtt: effAtt,
        effDef: effDef,
        attMods: attMods,
        defMods: defMods,
      );
      attLoss = pickCasualties(attGroups, attLossFraction, rng);
      attCasualties.addAll(attLoss);
      attGroups = removeCasualties(attGroups, attLoss);

      if (totalUnitCount(attGroups) <= 0) {
        return finisher.finish(
          winner: QuickBattleWinner.defender,
          provinceFlips: false,
        );
      }

      // Attacker state changed; recompute attacker strength only. Defender
      // groups and gun HP are unchanged so effDef remains valid.
      effAtt = attackerEffectiveStrength(
        input: input,
        attGroups: attGroups,
        attMods: attMods,
      );
      final defLossFraction = defenderLossFractionFromAttackerStrike(
        input: input,
        effAtt: effAtt,
        effDef: effDef,
        attMods: attMods,
        defMods: defMods,
      );
      defLoss = pickDefenderLosses(
        groups: defGroups,
        fraction: defLossFraction,
        rng: rng,
        mutableGuns: mutableGuns,
        useVirtualEmplaced: useVirtualEmplaced,
      );
      defCasualties.addAll(defLoss);
      defGroups = removeCasualties(defGroups, defLoss);
    }

    if (defLoss.length > attLoss.length && defLoss.isNotEmpty) {
      defGroups = degradeCohesion(defGroups);
    } else if (attLoss.length > defLoss.length && attLoss.isNotEmpty) {
      attGroups = degradeCohesion(attGroups);
    }

    if (totalUnitCount(defGroups) <= 0) {
      return finisher.finish(
        winner: QuickBattleWinner.attacker,
        provinceFlips: true,
      );
    }
    if (totalUnitCount(attGroups) <= 0) {
      return finisher.finish(
        winner: QuickBattleWinner.defender,
        provinceFlips: false,
      );
    }
  }

  return _resolveQuickBattleRoundLimitOutcome(
    finisher,
    attGroups: attGroups,
    defGroups: defGroups,
  );
}

QuickBattleResult _resolveQuickBattleRoundLimitOutcome(
  QuickBattleFinisher finisher, {
  required List<QuickBattleGroup> attGroups,
  required List<QuickBattleGroup> defGroups,
}) {
  final input = finisher.input;
  final finalAttStr =
      effectiveStrength(attGroups, input.attackerDeployment.laneTerrain) *
      input.attackerLeaderMultiplier;
  final finalDefStr =
      effectiveStrength(defGroups, input.defenderDeployment.laneTerrain) *
          input.defenderLeaderMultiplier +
      (finisher.useVirtualEmplaced
          ? aliveGunStrengthSum(finisher.mutableGuns)
          : 0.0);

  if (finalAttStr > finalDefStr * 1.2) {
    return finisher.finish(
      winner: QuickBattleWinner.attacker,
      provinceFlips: true,
    );
  }
  if (finalDefStr > finalAttStr * 1.2) {
    return finisher.finish(
      winner: QuickBattleWinner.defender,
      provinceFlips: false,
    );
  }
  return finisher.finish(
    winner: QuickBattleWinner.mutualExhaustion,
    provinceFlips: false,
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
