/// Pins the snapshot-driven bundled-Explore diagnostic surface of
/// [e2eBundledExploreRejectionDiagnostics]
/// (`app/integration_test/e2e_test_shared.dart`).
///
/// The fleet-reach test's final guard
/// (`new_game_fleet_reaches_new_world_e2e_test.dart` line ~408) calls this
/// helper to build the multi-line diagnostic embedded in the bundled-Explore
/// failure `fail()` message. The fail-message text is part of the
/// observable contract (it is grep-able from CI logs by the
/// `'No ctE2eNavalPanelSnapshot available for diagnostics.'` and `'diag:'`
/// prefixes) so a silent rename, line-order swap, or accidental
/// fail-open ("always emit the empty string") here would either:
///
///   - Hide the failing fleet-reach `availableWorkTargets` / `suggestedExplore`
///     details under a generic `fail()` message and erase the per-province
///     `workReason` / `moveReason` lines reviewers grep for when triaging
///     post-bundle #1869 regressions; or
///   - Make the deterministic per-explorer + per-province ordering
///     `(ascending by unit.id, ascending by province.id)` drift, masking
///     non-deterministic AI / order-engine state in CI runs where the
///     diagnostic is the only post-mortem record.
///
/// The function takes both [CtE2eNavalPanelSnapshot] and
/// [CtE2eCivilianPanelSnapshot] explicitly rather than reading the global
/// `ctE2eNavalPanelSnapshot` / `ctE2eCivilianPanelSnapshot` so the
/// diagnostic is deterministic and unit-testable (matches the lifted
/// [e2eNonHomeHumanFleetInNewWorldFromCtSnapshot] /
/// [e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot] /
/// [e2eExploreAssignEnabledFromCivilianSnapshot] precedents).
///
/// The integration suite cannot validate this directly today
/// (the `app_e2e_linux` lane is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so the widget-test
/// layer carries the behavioural pin (Refs GitHub #2336 AC1 / AC2).
library;

import 'package:colonizethis_app/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

const String _human = 'gp1';

const TurnState _orderingTurn = TurnState(
  phase: TurnPhase.orders,
  turnNumber: 1,
);

const MapTopology _emptyTopology = MapTopology();

const Orders _emptyOrders = Orders();

const RegionData _emptyRegion = RegionData();

Unit _explorer({
  required String id,
  required String provinceId,
  String? tileKey,
}) => Unit(
  id: id,
  type: kUnitTypeExplorer,
  ownerId: _human,
  locationProvinceId: provinceId,
  tileKey: tileKey,
);

WorldState _world({
  RegionData oldWorld = _emptyRegion,
  RegionData newWorld = _emptyRegion,
  Map<String, Map<String, String>> playerVisibilityByTile = const {},
}) => WorldState(
  turnState: _orderingTurn,
  oldWorld: oldWorld,
  newWorld: newWorld,
  playerVisibilityByTile: playerVisibilityByTile,
);

Game _game({
  RegionData oldWorld = _emptyRegion,
  RegionData newWorld = _emptyRegion,
  Map<String, Map<String, String>> playerVisibilityByTile = const {},
}) => Game(
  id: 'g1',
  worldState: _world(
    oldWorld: oldWorld,
    newWorld: newWorld,
    playerVisibilityByTile: playerVisibilityByTile,
  ),
  players: const [Player(id: _human, displayName: 'You', isHuman: true)],
);

CtE2eNavalPanelSnapshot _navalSnapshot({
  RegionData oldWorld = _emptyRegion,
  RegionData newWorld = _emptyRegion,
  Map<String, Map<String, String>> playerVisibilityByTile = const {},
  Orders draftOrders = _emptyOrders,
}) => CtE2eNavalPanelSnapshot(
  game: _game(
    oldWorld: oldWorld,
    newWorld: newWorld,
    playerVisibilityByTile: playerVisibilityByTile,
  ),
  humanPlayerId: _human,
  topology: _emptyTopology,
  draftOrders: draftOrders,
);

CtE2eCivilianPanelSnapshot _civilianSnapshot({
  Map<String, List<String>> availableWorkTargets = const {},
}) => CtE2eCivilianPanelSnapshot(
  game: _game(),
  humanPlayerId: _human,
  currentOrders: _emptyOrders,
  availableWorkTargets: availableWorkTargets,
);

void main() {
  suppressLogsForTests();

  group('e2eBundledExploreRejectionDiagnostics — fallback string', () {
    test('null navalSnapshot returns the canonical fallback line', () {
      // A null navalSnapshot must surface as the literal canonical string
      // (no `diag:` lines, no joined newlines, no empty string). The fleet
      // reach test embeds this directly in a `fail()` so a silent rename
      // or empty-string regression would erase the post-mortem signal CI
      // grep relies on.
      expect(
        e2eBundledExploreRejectionDiagnostics(
          navalSnapshot: null,
          civilianSnapshot: null,
        ),
        'No ctE2eNavalPanelSnapshot available for diagnostics.',
        reason:
            'Null navalSnapshot path returns the canonical fallback string '
            'verbatim; this is the early-exit contract (#2336 AC1).',
      );
    });

    test('null navalSnapshot + non-null civilian still returns fallback', () {
      // The null-naval branch fires before the civilian snapshot is read.
      // A regression that swapped argument order or inspected civilian
      // before naval would emit a different diagnostic and mask the
      // missing-naval root cause in CI failure messages.
      expect(
        e2eBundledExploreRejectionDiagnostics(
          navalSnapshot: null,
          civilianSnapshot: _civilianSnapshot(
            availableWorkTargets: const {
              'unit-a': <String>['explore'],
            },
          ),
        ),
        'No ctE2eNavalPanelSnapshot available for diagnostics.',
        reason:
            'Civilian snapshot must not be consulted when navalSnapshot is '
            'null — the canonical fallback line dominates.',
      );
    });
  });

  group('e2eBundledExploreRejectionDiagnostics — header lines', () {
    test('non-null naval, null civilian → header without availableWorkTargets', () {
      // The header lines are always emitted in this order:
      //   1. diag: player=<id>
      //   2. diag: civilianSnapshotAvailable=<bool>
      //   3. (optional) diag: availableWorkTargets=<...> — only when civilian
      //   4. diag: draftMoveOrders=<...>
      //   5. diag: suggestedExplore=<...>
      // Followed by an explorer block. Null civilian means line 3 is
      // omitted but `civilianSnapshotAvailable=false` is still present.
      final diag = e2eBundledExploreRejectionDiagnostics(
        navalSnapshot: _navalSnapshot(),
        civilianSnapshot: null,
      );
      expect(
        diag,
        contains('diag: player=$_human'),
        reason: 'Player id header line must appear verbatim.',
      );
      expect(
        diag,
        contains('diag: civilianSnapshotAvailable=false'),
        reason:
            'Civilian-snapshot-presence flag is always emitted; null '
            'civilian surfaces as "false" (not missing) so reviewers can '
            'distinguish absence from presence.',
      );
      expect(
        diag,
        isNot(contains('availableWorkTargets=')),
        reason:
            'availableWorkTargets line is conditional on civilian '
            'snapshot being non-null; omitting it for null civilian keeps '
            'header noise minimal and preserves the diagnostic contract.',
      );
      expect(
        diag,
        contains('diag: draftMoveOrders=[]'),
        reason:
            'No draft move orders → empty list literal; the prefix '
            'must remain so consumers can parse the line.',
      );
      expect(
        diag,
        contains('diag: suggestedExplore=[]'),
        reason:
            'No explorer suggestions in an empty game → empty list; '
            'the prefix anchors the line for grep.',
      );
    });

    test('non-null naval + civilian → availableWorkTargets line emitted', () {
      // The civilian-snapshot-present arm must add the
      // availableWorkTargets line with the map literal toString form.
      // A regression that dropped the conditional or inlined a
      // wrong-format string would diverge from the long-lived contract
      // surfaced in CI failure messages.
      final diag = e2eBundledExploreRejectionDiagnostics(
        navalSnapshot: _navalSnapshot(),
        civilianSnapshot: _civilianSnapshot(
          availableWorkTargets: const {
            'unit-a': <String>['explore', 'prospect'],
          },
        ),
      );
      expect(
        diag,
        contains('diag: civilianSnapshotAvailable=true'),
        reason: 'Non-null civilian surfaces as "true".',
      );
      expect(
        diag,
        contains('diag: availableWorkTargets={unit-a: [explore, prospect]}'),
        reason:
            'availableWorkTargets serializes via Dart Map.toString(). '
            'Preserving the exact format lets CI grep on the literal '
            'tile/target ids.',
      );
    });
  });

  group('e2eBundledExploreRejectionDiagnostics — no explorers branch', () {
    test('no explorers → ends with the canonical no-explorer line', () {
      // No explorer units in the human player view → header block plus
      // the single canonical closing line, with NO per-province probe
      // lines. A regression that emitted province lines anyway would
      // run O(provinces) order-engine probes on the cold failure path
      // for nothing (Refs `colonizethis-turn-resolution-budget.mdc`
      // "Avoid per-candidate debug logs in tight paths").
      final diag = e2eBundledExploreRejectionDiagnostics(
        navalSnapshot: _navalSnapshot(
          newWorld: const RegionData(
            provinces: [
              Province(id: 'newWorld|nwA', regionId: 'newWorld'),
              Province(id: 'newWorld|nwB', regionId: 'newWorld'),
            ],
          ),
        ),
        civilianSnapshot: null,
      );
      expect(
        diag,
        contains('diag: no explorer units found in player view.'),
        reason:
            'Closing canonical line for the zero-explorer fast path; '
            'reviewers grep on this text to confirm the no-explorer arm '
            'fired vs the per-province probe arm.',
      );
      expect(
        diag,
        isNot(contains('diag: explorer unit=')),
        reason:
            'Per-explorer header line must not appear when no explorer '
            'is present — confirms the early return prevents per-province '
            'iteration.',
      );
      expect(
        diag,
        isNot(contains('diag: province=')),
        reason:
            'Per-province probe block must not appear when no explorer '
            'is present (cold-path cost protection).',
      );
    });
  });

  group('e2eBundledExploreRejectionDiagnostics — per-province probe', () {
    test('explorer + multiple provinces → sorted per-province lines', () {
      // Two NW provinces (insertion order nwB, nwA), one OW province
      // (owA), and one explorer in OW. `allProvinces` walks both regions;
      // the helper sorts ascending by `province.id`. Expected sort order:
      //   newWorld|nwA, newWorld|nwB, oldWorld|owA.
      // A regression that dropped the sort or iterated in insertion order
      // would surface as `newWorld|nwB` before `newWorld|nwA`.
      final explorer = _explorer(
        id: 'ex1',
        provinceId: 'oldWorld|owA',
        tileKey: 'oldWorld|owA|0|0',
      );
      final diag = e2eBundledExploreRejectionDiagnostics(
        navalSnapshot: _navalSnapshot(
          oldWorld: RegionData(
            provinces: const [Province(id: 'oldWorld|owA', regionId: 'oldWorld')],
            units: [explorer],
          ),
          newWorld: const RegionData(
            provinces: [
              Province(id: 'newWorld|nwB', regionId: 'newWorld'),
              Province(id: 'newWorld|nwA', regionId: 'newWorld'),
            ],
          ),
        ),
        civilianSnapshot: null,
      );

      // Explorer header is emitted exactly once.
      expect(
        diag,
        contains(
          'diag: explorer unit=ex1 atProvince=oldWorld|owA '
          'tileKey=oldWorld|owA|0|0',
        ),
        reason:
            'Per-explorer header line includes id, provinceId, and the '
            'resolved tileKey (non-null path renders the tile key '
            'literal, not the `(null)` fallback).',
      );
      // Per-province lines emitted in ascending province.id order.
      final lines = diag.split('\n');
      final nwAIndex = lines.indexWhere(
        (l) => l.startsWith('diag: province=newWorld|nwA '),
      );
      final nwBIndex = lines.indexWhere(
        (l) => l.startsWith('diag: province=newWorld|nwB '),
      );
      final owAIndex = lines.indexWhere(
        (l) => l.startsWith('diag: province=oldWorld|owA '),
      );
      expect(
        nwAIndex,
        greaterThanOrEqualTo(0),
        reason: 'NW province nwA probe line must be emitted.',
      );
      expect(
        nwBIndex,
        greaterThanOrEqualTo(0),
        reason: 'NW province nwB probe line must be emitted.',
      );
      expect(
        owAIndex,
        greaterThanOrEqualTo(0),
        reason: 'OW province owA probe line must be emitted.',
      );
      expect(
        nwAIndex < nwBIndex && nwBIndex < owAIndex,
        isTrue,
        reason:
            'Per-province lines must be emitted in ascending province.id '
            'order (lexicographic): newWorld|nwA, newWorld|nwB, '
            'oldWorld|owA. Insertion order in RegionData (nwB before nwA) '
            'is overridden by the trailing sort — pinning this here keeps '
            'CI diagnostics deterministic across map-generation reorderings.',
      );
    });

    test('tileKey null surfaces as "(null)" in the explorer header', () {
      // Explorer without a tile key (typical for a freshly-deployed
      // explorer) must render `tileKey=(null)`. A regression that
      // emitted the empty string or "null" without the parens would
      // erase the visual signal CI reviewers use to spot un-deployed
      // explorers in the failure log.
      final explorer = _explorer(id: 'ex1', provinceId: 'oldWorld|owA');
      final diag = e2eBundledExploreRejectionDiagnostics(
        navalSnapshot: _navalSnapshot(
          oldWorld: RegionData(
            provinces: const [Province(id: 'oldWorld|owA', regionId: 'oldWorld')],
            units: [explorer],
          ),
        ),
        civilianSnapshot: null,
      );
      expect(
        diag,
        contains(
          'diag: explorer unit=ex1 atProvince=oldWorld|owA tileKey=(null)',
        ),
        reason:
            'Null tileKey renders as literal "(null)" with parens — that '
            'rendering is the documented contract and CI grep signal.',
      );
    });

    test('province ownerKind classifications cover none / tribe / minor / gp / self', () {
      // Owner classification:
      //   ownerId == null            → ownerKind=none
      //   ownerId == self (gp1)      → ownerKind=self
      //   ownerId in tribes set      → ownerKind=tribe
      //   ownerId in minorNations    → ownerKind=minor
      //   ownerId is GP otherwise    → ownerKind=gp
      // We construct one province per kind and assert the rendered
      // `ownerKind=` token. A regression in the precedence (e.g. a
      // tribe in the minor list would now show as `minor`) would
      // surface immediately.
      final explorer = _explorer(id: 'ex1', provinceId: 'oldWorld|none');
      final game = Game(
        id: 'g-owner-kinds',
        worldState: _world(
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'oldWorld|none', regionId: 'oldWorld'),
              Province(id: 'oldWorld|self', regionId: 'oldWorld', ownerId: _human),
              Province(id: 'oldWorld|tribe', regionId: 'oldWorld', ownerId: 't1'),
              Province(id: 'oldWorld|minor', regionId: 'oldWorld', ownerId: 'm1'),
              Province(id: 'oldWorld|gp', regionId: 'oldWorld', ownerId: 'gp2'),
            ],
            units: [explorer],
          ),
        ),
        players: const [
          Player(id: _human, displayName: 'You', isHuman: true),
          Player(id: 'gp2', displayName: 'GP2', isHuman: false),
        ],
        tribes: const [Tribe(id: 't1', displayName: 'T1')],
        minorNations: const [MinorNation(id: 'm1', displayName: 'M1')],
      );
      final snap = CtE2eNavalPanelSnapshot(
        game: game,
        humanPlayerId: _human,
        topology: _emptyTopology,
        draftOrders: _emptyOrders,
      );
      final diag = e2eBundledExploreRejectionDiagnostics(
        navalSnapshot: snap,
        civilianSnapshot: null,
      );
      expect(
        diag,
        contains(
          'diag: province=oldWorld|none owner=(none) ownerKind=none ',
        ),
        reason: 'Null ownerId surfaces as `(none)` and `ownerKind=none`.',
      );
      expect(
        diag,
        contains(
          'diag: province=oldWorld|self owner=$_human ownerKind=self ',
        ),
        reason: 'Self-owned province surfaces as `ownerKind=self`.',
      );
      expect(
        diag,
        contains('diag: province=oldWorld|tribe owner=t1 ownerKind=tribe '),
        reason: 'Tribe-owned province surfaces as `ownerKind=tribe`.',
      );
      expect(
        diag,
        contains('diag: province=oldWorld|minor owner=m1 ownerKind=minor '),
        reason:
            'Minor-owned province surfaces as `ownerKind=minor` (tribe '
            'precedence already applied earlier in the cascade).',
      );
      expect(
        diag,
        contains('diag: province=oldWorld|gp owner=gp2 ownerKind=gp '),
        reason:
            'Other-GP province surfaces as `ownerKind=gp` (fall-through '
            'arm; not classified as tribe/minor/self).',
      );
    });
  });

  group('e2eBundledExploreRejectionDiagnostics — determinism', () {
    test('identical inputs yield byte-identical strings (pure)', () {
      // Two adjacent calls with the same snapshots must produce the
      // same multi-line string. Two fresh OrderEngine instances per
      // probe + the trailing province sort guarantee this, but the
      // pin protects against future mutations that leak state across
      // calls (e.g. a memoizing cache keyed by mutable map identity).
      final explorer = _explorer(id: 'ex1', provinceId: 'oldWorld|owA');
      final snap = _navalSnapshot(
        oldWorld: RegionData(
          provinces: const [Province(id: 'oldWorld|owA', regionId: 'oldWorld')],
          units: [explorer],
        ),
        newWorld: const RegionData(
          provinces: [Province(id: 'newWorld|nwA', regionId: 'newWorld')],
        ),
      );
      final civ = _civilianSnapshot(
        availableWorkTargets: const {
          'unit-a': <String>['explore'],
        },
      );
      final first = e2eBundledExploreRejectionDiagnostics(
        navalSnapshot: snap,
        civilianSnapshot: civ,
      );
      final second = e2eBundledExploreRejectionDiagnostics(
        navalSnapshot: snap,
        civilianSnapshot: civ,
      );
      expect(
        second,
        first,
        reason:
            'Pure function pin (Refs #2336): identical inputs must yield '
            'byte-identical multi-line strings. A regression that leaked '
            'OrderEngine state, used a non-deterministic sort, or read a '
            'global ctE2e* snapshot mid-call would surface here as a '
            'string diff.',
      );
    });
  });
}
