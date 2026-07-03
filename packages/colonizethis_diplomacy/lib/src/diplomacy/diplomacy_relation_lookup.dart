/// Relation and overture lookup helpers for diplomacy. SPEC/program/diplomacy-resolution.md.
/// Shared by diplomacy_resolver and order validators.
library;

import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';

import 'package:colonizethis_world/src/utils/expando_index.dart';
import 'package:colonizethis_world/src/world/diplomatic_relation_lookup.dart';

export 'diplomacy_relation_constants.dart';
export 'diplomacy_relation_upsert.dart';
export 'package:colonizethis_world/src/world/diplomatic_relation_lookup.dart';
export 'package:colonizethis_world/src/world/province_owner_cache.dart'
    show oldWorldProvinceCountOwnedBy;

import 'diplomacy_relation_constants.dart';

/// Returns the number of provinces owned by [factionId] (Minor or Tribe) in
/// [game].
///
/// Reads the count from the shared read-only [ProvinceOwnerCache] projection
/// (memoised per [WorldState] identity) instead of recomputing a separate
/// per-[Game] province-count scan — consolidating onto the single ownership
/// projection (Phase 6b, SPEC/program/worldstate-projection.md; Refs #3393).
/// Counts only provinces whose non-null `ownerId == factionId`, identical to
/// the prior full-world `allProvinces` scan.
int provinceCountOwnedBy(Game game, String factionId) =>
    ProvinceOwnerCache.of(game.worldState).countOwnedBy(factionId);

/// Join Empire cost in pounds for absorbing [targetId] (Minor or Tribe).
int joinEmpireCostForMinorOrTribe(Game game, String targetId) {
  final n = provinceCountOwnedBy(game, targetId);
  return joinEmpireBaseCost + n * joinEmpirePerProvinceCost;
}

/// Directed GP → Minor/Tribe overture rows, keyed by `_overtureLookupKey`.
/// Routed through the shared [ExpandoIndex] utility (Refs #2836 AC 2).
final ExpandoIndex<Game, Map<String, OvertureState>>
_gameOvertureStatesByGpTargetIndex =
    ExpandoIndex<Game, Map<String, OvertureState>>(
      'gameOvertureStatesByGpTarget',
      (game) {
        final map = <String, OvertureState>{};
        for (final o in game.overtureStates) {
          map.putIfAbsent(_overtureLookupKey(o.gpId, o.targetId), () => o);
        }
        return map;
      },
    );

String _overtureLookupKey(String gpId, String targetId) => '$gpId|$targetId';

Map<String, OvertureState> _overtureStatesByLookupKey(Game game) =>
    _gameOvertureStatesByGpTargetIndex.get(game);

/// Returns overture state for GP–Minor/Tribe, or null.
OvertureState? getOverture(Game game, String gpId, String targetId) {
  return _overtureStatesByLookupKey(game)[_overtureLookupKey(gpId, targetId)];
}

/// Embassy-tier overture from [gpId] toward [targetId]. SPEC/game/world-market.md.
bool hasEmbassyOverture(Game game, String gpId, String targetId) {
  final o = getOverture(game, gpId, targetId);
  return o != null && o.hasEmbassy;
}

/// Consulate-tier (or higher) overture from [gpId] toward [targetId].
///
/// Gate for the #3753 R7.3 world-market sell-priority relation tiebreaker
/// (`SPEC/game/world-market.md` § Sell-priority relation tiebreaker): only
/// buyers holding at least a `tradeConsulate` overture with a Minor/Tribe
/// seller participate in the relation-score ordering.
bool hasConsulateOverture(Game game, String gpId, String targetId) {
  final o = getOverture(game, gpId, targetId);
  return o != null && o.hasConsulate;
}

/// Bilateral FTP active between [factionId1] and [factionId2].
bool hasFtpPartnership(Game game, String factionId1, String factionId2) {
  return game.ftpPartnershipKeys.contains(pairKey(factionId1, factionId2));
}

/// Active FTP pair keys for world-market matching. SPEC/program/world-market-resolution.md.
Set<String> ftpPairKeysFromGame(Game game) =>
    Set<String>.from(game.ftpPartnershipKeys);

/// Canonical `pairKey` set of `(colonyTribeId, boycottedTargetGpId)` pairs the
/// World Market deal matcher must refuse to fill (Refs #3753 R6 boycott colony
/// trade embargo).
///
/// For every active `BoycottState { gpId: A, targetGpId: B }`, every Tribe `T`
/// that is a colony of A (`ColonyState.colonyOfGpId == A`) contributes
/// `pairKey(T, B)`. The key is symmetric, so the matcher's
/// `pairKey(sellerFactionId, buyerFactionId)` lookup blocks trade in **both**
/// directions between B and A's colony Tribes — B buying goods a colony Tribe
/// sells, and a colony Tribe buying goods B sells. The result is empty when no
/// boycott is active or no boycotting GP holds a colony, which the matcher
/// treats as a no-op (legacy matching). SPEC/game/diplomacy.md § GP–Tribe Rules
/// (Boycott); SPEC/program/world-market-resolution.md § Deal matching engine.
Set<String> boycottBlockedTradePairKeys(Game game) {
  if (game.boycottStates.isEmpty || game.colonyStates.isEmpty) {
    return const <String>{};
  }
  final colonyTribesByGp = <String, List<String>>{};
  for (final colony in game.colonyStates) {
    colonyTribesByGp
        .putIfAbsent(colony.colonyOfGpId, () => <String>[])
        .add(colony.tribeId);
  }
  final keys = <String>{};
  for (final boycott in game.boycottStates) {
    final colonyTribes = colonyTribesByGp[boycott.gpId];
    if (colonyTribes == null) continue;
    for (final tribeId in colonyTribes) {
      keys.add(pairKey(tribeId, boycott.targetGpId));
    }
  }
  return keys;
}

/// Resolves the **favoured trading partner** of a Minor Nation or Tribe
/// [minorOrTribeId] (Refs #3753 R7.1), or `null` when it is undefined.
///
/// This is a deterministic read-only lookup, distinct from the bilateral GP–GP
/// Favored Trading Partner agreement ([hasFtpPartnership] / `ftpPartnershipKeys`):
///
/// - If [minorOrTribeId] is a **colony** Tribe (a [ColonyState] with
///   `tribeId == minorOrTribeId` exists), its **suzerain** (`colonyOfGpId`) is
///   the favoured partner regardless of any other Great Power's relation score.
/// - Otherwise (independent Tribe or Minor Nation), the Great Power with the
///   **highest decimal relation score** ([DiplomacyRelation.score]) toward
///   [minorOrTribeId] among all Great Powers ([Game.players]) that hold a
///   relation with it. Ties at the score break deterministically by **ascending
///   faction id**.
/// - When no Great Power holds a [DiplomacyRelation] with [minorOrTribeId] (and
///   it is not a colony), the result is `null` (undefined).
///
/// The favoured trading partner, the world-market sell-priority relation
/// tiebreaker (R7.3), first right of refusal (R7.2), and overseas profit-share
/// (R8) are independent concepts. SPEC/game/diplomacy.md § Favoured trading
/// partner (Refs #3753 R7.1).
String? favouredTradingPartner(Game game, String minorOrTribeId) {
  for (final colony in game.colonyStates) {
    if (colony.tribeId == minorOrTribeId) return colony.colonyOfGpId;
  }
  String? best;
  num? bestScore;
  for (final player in game.players) {
    final rel = getRelation(game, player.id, minorOrTribeId);
    if (rel == null) continue;
    final score = rel.score;
    final isBetter =
        bestScore == null ||
        score > bestScore ||
        (score == bestScore && player.id.compareTo(best!) < 0);
    if (isBetter) {
      bestScore = score;
      best = player.id;
    }
  }
  return best;
}

/// True if [playerId] may attack [targetOwnerId]: at war or declaring war this turn.
/// Used by move validator for GP and Minor/Tribe attack checks. SPEC/program/orders.md.
bool canAttackWithWarOrDeclaring(
  Game game,
  String playerId,
  String targetOwnerId,
  List<DiplomaticOrder> diplomaticOrders,
) {
  final rel = getRelation(game, playerId, targetOwnerId);
  final atWar = rel?.atWar ?? false;
  final declaringWarThisTurn = diplomaticOrders.any(
    (o) =>
        o.type == DiplomaticOrderType.declareWar &&
        o.targetFactionId == targetOwnerId,
  );
  return atWar || declaringWarThisTurn;
}

/// Diplomatic history events involving both [factionA] and [factionB], newest first.
/// SPEC/ui/diplomacy-panel.md § Diplomacy Detail — history contents.
List<DiplomaticEvent> diplomaticHistoryForPair(
  Game game,
  String factionA,
  String factionB,
) {
  final list = game.diplomaticHistoryEvents
      .where(
        (e) =>
            e.participants.contains(factionA) &&
            e.participants.contains(factionB),
      )
      .toList();
  list.sort((a, b) {
    final turnCmp = b.turn.compareTo(a.turn);
    if (turnCmp != 0) return turnCmp;
    return b.intraTurnIndex.compareTo(a.intraTurnIndex);
  });
  return list;
}
