part of '../e2e_bundled_explore_rejection_diagnostics_test.dart';

void registerBundledExploreProbeGroup() {
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

}
