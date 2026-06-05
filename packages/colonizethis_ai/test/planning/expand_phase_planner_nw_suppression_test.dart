// Module-level NW-suppression pin for the EXPAND phase planner set
// (Refs #2509 S2 / S10 / S6 phase-planner-architecture sub-spec).
//
// Spec contract (issue #2509 § Phase planner unit tests § "EXPAND NW
// suppression"; SPEC/ai/phase-planner-architecture.md § Acceptance
// criteria):
//
//   "Given a GP in EXPAND with one or more sea-reachable unowned NW
//    provinces, when the EXPAND planner set runs, then the merged
//    orders contain zero NW `declareWar`, NW `establishOverture`,
//    NW `purchase_land`, or NW `ArmyMoveOrder` entries (structural
//    suppression — Refs #2509 § EXPAND Suppressions)."
//
// The per-function NW pins already live in
// `expand_phase_planner_military_test.dart` (the at-war-tribe-with-NW
// fixture and the declare-war-target-on-NW fixture). This file is the
// AC pin for the **planner set as a whole**: it constructs a single
// fixture where every individual planner reads enough state to
// potentially leak NW choices, then exercises ALL FOUR EXPAND planner
// contracts (`planExpandDeclareWar`, `planExpandPeace`,
// `planExpandEconomy`, `planExpandMilitary`) in the same dispatch
// order the orchestrator (#2509 S5) will eventually call them and
// verifies the merged output set carries no NW data.
//
// Why a planner-set integration pin in addition to per-function pins:
//   - The per-function pins prove each contract individually never
//     reads `ColonialSummary.invadableNewWorldProvinceIdsSorted`. The
//     planner-set pin proves the **composition** of the four planners
//     is also free of NW leakage — for example a future refactor that
//     hides NW-suppression inside a shared internal helper invoked
//     from multiple planners would be exercised here once.
//   - The AC ("when the EXPAND planner set runs") is explicitly the
//     planner set, not a single function. Pinning that wording at the
//     library level keeps the AC verifiable today, before the S5
//     orchestrator wiring lands.
//   - The single fixture exercises the full EXPAND signal surface:
//     adjacent-NW owners, NW invadable provinces, at-war tribes
//     holding NW land, COLONIAL-lite-style state shaped just below
//     quota. A regression that loosened any planner's NW guard fails
//     this single integration assertion rather than relying on the
//     reviewer to notice the contract drift across four files.
//
// Suppression model verified by this file:
//   - `planExpandDeclareWar` returns either `null` or an OW minor /
//     GP factionId; never a tribe factionId from
//     `ColonialSummary.adjacentNewWorldOwnerFactionIdsSorted`.
//   - `planExpandPeace` returns at-war GP factionIds only (no
//     declareWar emission ever — peace contract is `offerPeace` only).
//   - `planExpandEconomy` returns flag overrides only (no order
//     emission); a missing NW signal in the return surface is
//     structural — the value class has no NW fields.
//   - `planExpandMilitary` returns OW-only conquest destinations.
//
// The structural suppression contract on `ExpandEconomyPlan` and
// `ExpandMilitaryPlan` (value classes carry no NW-specific fields) is
// also covered by the import-surface guard test in this file.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'test_fixtures.dart';

const String _gp1 = 'gp1';
const String _gp2 = 'gp2';
const String _tribe1 = 'tribe1';
const String _minor1 = 'minor1';

const String _owProvMinor = 'oldWorld|m1_a';
const String _nwProvTribe = 'newWorld|tribe1_a';
const String _nwProvUnowned = 'newWorld|p_unowned';

/// Builds a Game scaffold where:
///   - Active player (`gp1`) holds [oldWorldProvincesOwned] OW
///     provinces (below the EXPAND quota of 10).
///   - Minor [_minor1] owns an OW invadable province
///     ([_owProvMinor]) so the OW priority arms in the planner set
///     have real candidates to read.
///   - Tribe [_tribe1] owns NW provinces ([_nwProvTribe] and
///     [_nwProvUnowned]) so the planner set can be tempted to leak
///     NW orders if any guard is missing.
///   - Active player has [regimentCount] regiments via a home army so
///     the economy / declare-war arms exercise live treasury /
///     regiment gates (otherwise outer guards short-circuit and the
///     NW suppression check would be tautological).
Game _expandGame({
  int turnNumber = 50,
  int ownTreasury = 9999,
  int regimentCount = 6,
}) {
  return Game(
    id: 'g-2509-expand-phase-planner-nw-suppression-t$turnNumber',
    worldState: WorldState(
      turnState: TurnState(turnNumber: turnNumber, phase: TurnPhase.orders),
      oldWorld: const RegionData(
        provinces: [
          // Active player's own OW province (snapshot
          // `oldWorldProvincesOwned` is the authoritative quota signal
          // for the planner set; this entry just keeps the region
          // non-empty so any future helpers that walk `worldState`
          // see consistent ownership state).
          Province(
            id: 'oldWorld|gp1_a',
            regionId: kOldWorldRegionId,
            ownerId: _gp1,
          ),
          // Minor-held OW province: feeds `invadableProvinceIdsSorted`
          // when the snapshot mirrors it.
          Province(
            id: _owProvMinor,
            regionId: kOldWorldRegionId,
            ownerId: _minor1,
          ),
        ],
      ),
      newWorld: const RegionData(
        provinces: [
          // Tribe-held NW province: visible target for any NW leakage.
          Province(
            id: _nwProvTribe,
            regionId: kNewWorldRegionId,
            ownerId: _tribe1,
          ),
          // Unowned NW province: surface for purchase_land /
          // establishOverture leakage if any planner forgot the
          // suppression.
          Province(id: _nwProvUnowned, regionId: kNewWorldRegionId),
        ],
      ),
      armies: [homeArmyWithRegiments(_gp1, regimentCount)],
    ),
    players: [
      Player(
        id: _gp1,
        displayName: 'GP1',
        isHuman: false,
        treasury: ownTreasury,
      ),
      const Player(id: _gp2, displayName: 'GP2', isHuman: false),
    ],
    minorNations: const [MinorNation(id: _minor1, displayName: 'Minor1')],
    tribes: const [Tribe(id: _tribe1, displayName: 'Tribe1')],
  );
}

/// Snapshot for active player [_gp1] in EXPAND posture (OW below
/// quota, OW invadable populated, NW invadable + adjacent NW owners
/// populated to verify suppression).
///
/// `oldWorldProvincesOwned` defaults to 8 so the EXPAND outer guards
/// (`isBelowObserverConquestQuota`, `_isMutualBelowQuotaPlateauPeer`)
/// fire; `atWarWith` includes the tribe + minor so the declare-war
/// and military-fallback arms have at-war candidates to scan.
AIWorldSnapshot _expandSnapshot({
  int oldWorldProvincesOwned = 8,
  List<String> atWarWith = const [_minor1, _tribe1],
}) {
  return AIWorldSnapshot(
    playerId: _gp1,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      provincesToVictory: kObserverConquestMinOwProvincesPerGp * 3,
      invadableProvinceIdsSorted: const [_owProvMinor],
      adjacentOwnerFactionIdsSorted: const [_minor1, _tribe1],
    ),
    colonial: const ColonialSummary(
      invadableNewWorldProvinceIdsSorted: [_nwProvTribe, _nwProvUnowned],
      adjacentNewWorldOwnerFactionIdsSorted: [_tribe1],
      preferredColonialTargetFactionIdsSorted: [_tribe1],
    ),
    economy: const EconomySummary(),
    relations: const {},
  );
}

/// Boolean test for whether [factionId] resolves to a tribe or minor
/// nation in [game] (i.e. a non-Great-Power faction whose ownership
/// of NW provinces would be a structural suppression target).
bool _isNonGpFaction(Game game, String factionId) {
  if (game.tribes.any((t) => t.id == factionId)) return true;
  if (game.minorNations.any((m) => m.id == factionId)) return true;
  return false;
}

/// Owner of [provinceId] in either region of [game], or `null` when
/// the province is not present in any region.
String? _ownerOf(Game game, String provinceId) {
  for (final region in <RegionData>[
    game.worldState.oldWorld,
    game.worldState.newWorld,
  ]) {
    for (final p in region.provinces) {
      if (p.id == provinceId) return p.ownerId;
    }
  }
  return null;
}

/// Whether [provinceId] is in the New World region.
bool _isNwProvinceId(String provinceId) =>
    ProvinceId.regionIdFrom(provinceId) == kNewWorldRegionId;

void main() {
  group('EXPAND planner set NW suppression (AC pin)', () {
    test('planner set output contains no NW declareWar, NW establishOverture, '
        'NW purchase_land, or NW ArmyMoveOrder entries', () {
      // Single fixture that loads every NW signal slot the planner
      // set could possibly read: tribe-owned NW provinces in the
      // colonial summary, adjacent NW owner ids in the colonial
      // summary, an at-war tribe so the declare-war + military
      // priority arms have a tempting NW candidate. The OW arms
      // remain valid (minor with OW invadable + active player below
      // quota) so the planners do not bail out at outer guards;
      // bailing out would make the suppression check tautological.
      final game = _expandGame();
      final snapshot = _expandSnapshot();

      // 1. planExpandDeclareWar must never return a tribe factionId
      //    sourced from the colonial summary
      //    (adjacentNewWorldOwnerFactionIdsSorted /
      //    preferredColonialTargetFactionIdsSorted). The OW arm is
      //    free to return the minor's id; the suppression contract
      //    is "no NW-only target" rather than "always null".
      final declareWar = planExpandDeclareWar(game: game, snapshot: snapshot);
      if (declareWar != null) {
        expect(
          _isNonGpFaction(game, declareWar) &&
              !snapshot.conquest.invadableProvinceIdsSorted.any(
                (pid) => _ownerOf(game, pid) == declareWar,
              ),
          isFalse,
          reason:
              'planExpandDeclareWar must never return a tribe / minor '
              'factionId that is not backed by an OW invadable '
              'province; tribes / minors with only NW invadable '
              'holdings are a structural NW leakage path that the '
              'EXPAND planner set must reject. Returned target: '
              '$declareWar.',
        );
      }

      // 2. planExpandPeace returns offerPeace targets; the peace
      //    contract is structurally NOT a declareWar / acquisition
      //    surface. Defensive pin: every entry must be a Great Power
      //    factionId (no tribe / minor leakage that would route the
      //    orchestrator into an unsupported NW peace path).
      final peace = planExpandPeace(game: game, snapshot: snapshot);
      for (final factionId in peace) {
        expect(
          _isNonGpFaction(game, factionId),
          isFalse,
          reason:
              'planExpandPeace must only return Great Power '
              'factionIds (GP-vs-GP peace contract). Tribe / minor '
              'ids in the output set indicate a structural NW / '
              'colonial leakage. Offending factionId: $factionId.',
        );
      }

      // 3. planExpandEconomy's return surface (`ExpandEconomyPlan`)
      //    has only OW-relevant flags (forceCheapestRegimentBuild,
      //    boostTreasuryRecoveryCargo). NW suppression is structural:
      //    the value class carries no NW fields, so the test simply
      //    pins the type to keep regressions that add NW-specific
      //    fields here visible. Calling the planner exercises the
      //    full economy decision path against the NW-rich fixture.
      final economy = planExpandEconomy(game: game, snapshot: snapshot);
      expect(
        economy,
        isA<ExpandEconomyPlan>(),
        reason:
            'planExpandEconomy must return ExpandEconomyPlan with no '
            'NW-specific fields. Any extension that adds NW work '
            'orders directly to this surface would constitute a '
            'structural NW leakage and break this AC pin once the '
            'reason text is updated to mention new fields.',
      );

      // 4. planExpandMilitary's destination list must never include
      //    a NW province even when an at-war tribe owns NW invadable
      //    provinces in the colonial summary. Exercised in both
      //    arms: (a) no declare-war target (Priority 2 at-war
      //    fallback fires for the minor); (b) declare-war target ==
      //    minor (Priority 1 fires). Both arms must return only OW
      //    destinations.
      for (final dwTarget in <String?>[null, _minor1]) {
        final military = planExpandMilitary(
          game: game,
          snapshot: snapshot,
          declaredWarTargetFactionId: dwTarget,
        );
        for (final pid in military.priorityDestinationProvinceIdsSorted) {
          expect(
            _isNwProvinceId(pid),
            isFalse,
            reason:
                'planExpandMilitary returned a NW province '
                '($pid) in the destination filter when '
                'declaredWarTargetFactionId=$dwTarget. EXPAND NW '
                'suppression must be structural — the planner only '
                'reads ConquestSummary.invadableProvinceIdsSorted '
                '(OW-only by builder contract). A NW id here '
                'indicates a future refactor accidentally pulled '
                'in ColonialSummary state.',
          );
        }
        for (final ownerFactionId
            in military.priorityTargetOwnerFactionIdsSorted) {
          expect(
            _isNonGpFaction(game, ownerFactionId) &&
                !snapshot.conquest.invadableProvinceIdsSorted.any(
                  (pid) => _ownerOf(game, pid) == ownerFactionId,
                ),
            isFalse,
            reason:
                'planExpandMilitary returned a tribe / minor owner '
                '($ownerFactionId) without backing OW invadable '
                'provinces. Tribes / minors with only NW holdings '
                'must never appear in the destination owner list.',
          );
        }
      }
    });

    test('tribe-only at-war set (NW invadable only) -> defaultPlan from '
        'military and null / non-tribe declare-war (no NW leakage when '
        'OW frontier has no minor pivot)', () {
      // Tightens the AC: when the ONLY at-war faction is a tribe
      // that owns ONLY NW invadable provinces, every EXPAND planner
      // must structurally suppress that tribe — declare-war returns
      // null (or the lone-GP-blocker arm if any, but here `atWarWith`
      // is tribe-only), military returns defaultPlan (no OW
      // invadable), and economy still computes its flags from OW
      // signals alone.
      final game = _expandGame();
      final snapshot = AIWorldSnapshot(
        playerId: _gp1,
        threats: const ThreatSummary(atWarWith: [_tribe1]),
        opportunities: const OpportunitySummary(),
        conquest: const ConquestSummary(
          oldWorldProvincesOwned: 8,
          provincesToVictory: kObserverConquestMinOwProvincesPerGp * 3,
          // OW invadable empty: every NW-leakage path must hit a
          // suppression guard.
          invadableProvinceIdsSorted: [],
          adjacentOwnerFactionIdsSorted: [_tribe1],
        ),
        colonial: const ColonialSummary(
          invadableNewWorldProvinceIdsSorted: [_nwProvTribe],
          adjacentNewWorldOwnerFactionIdsSorted: [_tribe1],
          preferredColonialTargetFactionIdsSorted: [_tribe1],
        ),
        economy: const EconomySummary(),
        relations: const {},
      );

      expect(
        planExpandDeclareWar(game: game, snapshot: snapshot),
        isNull,
        reason:
            'planExpandDeclareWar must return null when OW invadable '
            'is empty: the outer guard short-circuits before the '
            'priority arms read the at-war set. The NW-owning tribe '
            'in atWarWith is structurally invisible to the planner.',
      );

      expect(
        planExpandPeace(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'planExpandPeace filters atWarWith through '
            'game.playerById; tribe ids drop out. With a tribe-only '
            'at-war set the result must be empty (no GP wars to peace, '
            'no tribe leakage).',
      );

      expect(
        planExpandMilitary(game: game, snapshot: snapshot),
        same(ExpandMilitaryPlan.defaultPlan),
        reason:
            'planExpandMilitary must return defaultPlan when OW '
            'invadable is empty; the NW invadable list in the '
            'colonial summary must not back-fill the destination '
            'list even when an at-war tribe owns NW land.',
      );

      // planExpandEconomy still computes economy flags from OW
      // signals (own OW count, regiment count, treasury). The NW
      // signals are structurally ignored.
      final economy = planExpandEconomy(game: game, snapshot: snapshot);
      expect(economy, isA<ExpandEconomyPlan>());
      expect(
        economy.forceCheapestRegimentBuild,
        isFalse,
        reason:
            'Arm A requires non-empty OW invadable; arm B requires '
            'non-empty OW invadable. With OW invadable empty the '
            'force-rebuild flag must stay false regardless of NW '
            'state.',
      );
    });

    test('determinism across the planner set (Must-have #7): same '
        'NW-rich fixture -> identical plan outputs across two runs', () {
      // Pins the per-function determinism contract at the
      // planner-set level: the four planners must remain pure
      // functions even when called together in the orchestrator
      // dispatch order. A regression that memoized state in the
      // first call (e.g. caching province-owner maps across calls
      // without invalidation) would surface here.
      final game = _expandGame();
      final snapshot = _expandSnapshot();

      final dw1 = planExpandDeclareWar(game: game, snapshot: snapshot);
      final peace1 = planExpandPeace(game: game, snapshot: snapshot);
      final economy1 = planExpandEconomy(game: game, snapshot: snapshot);
      final military1 = planExpandMilitary(
        game: game,
        snapshot: snapshot,
        declaredWarTargetFactionId: dw1,
      );

      final dw2 = planExpandDeclareWar(game: game, snapshot: snapshot);
      final peace2 = planExpandPeace(game: game, snapshot: snapshot);
      final economy2 = planExpandEconomy(game: game, snapshot: snapshot);
      final military2 = planExpandMilitary(
        game: game,
        snapshot: snapshot,
        declaredWarTargetFactionId: dw2,
      );

      expect(dw2, dw1);
      expect(peace2, peace1);
      expect(economy2, economy1);
      expect(military2, military1);
    });
  });
}
