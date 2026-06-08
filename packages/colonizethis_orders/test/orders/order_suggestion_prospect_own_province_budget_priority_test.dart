import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

// Refs #2847 § Old World mineral feedstock prospect localization (gp1 residual).
//
// `suggestWorkOrders` shares a single decrementing
// `WorkSuggestionProbeBudget` (`kMaxWorkProbeAttemptsPerPlayerPass`, default
// 64) across **all** of a player's units in one pass. A large empire's
// earlier explorers can drain that shared budget on remote explore/prospect
// probes before a later co-located feedstock Explorer's prospect pass runs,
// so its owned, co-located, unprospected mineral tile never produces a
// `prospect` candidate even though the Explorer stands on the tile.
//
// On seed 42 this is exactly why gp1 (many New World explorers, reserved
// feedstock Explorer reached late) prospects its Old World `iron` tile on
// 0/59 gate-active turns while gp2 (budget survives) prospects on 59/59.
//
// The fix exempts the Explorer's **own** (current) province prospect probe
// from the shared budget — a bounded, high-value action capped per province
// by `kMaxWorkProbeAttemptsPerUnitPerTarget` — so the co-located candidate is
// never starved by earlier units. Remote provinces still consume the shared
// budget.
void main() {
  group(
    'suggestWorkOrders exempts own-province prospect from the shared probe '
    'budget (Refs #2847 H8-extraction gp1 residual)',
    () {
      const playerId = 'gp1';
      const ow = kRegionOldWorld;

      // Remote owned mineral province scanned by every explorer (sorts first
      // lexicographically): four unprospected `iron` tiles drain the shared
      // budget on each draining explorer's prospect pass.
      const drainProvinceId = 'oldWorld|aaa_drain';
      const drainTiles = <String>[
        'oldWorld|aaa_drain|0|0',
        'oldWorld|aaa_drain|1|0',
        'oldWorld|aaa_drain|2|0',
        'oldWorld|aaa_drain|3|0',
      ];

      // The co-located feedstock Explorer's own province (sorts last) holds a
      // single owned unprospected `iron` tile.
      const feedstockProvinceId = 'oldWorld|zzz_feedstock';
      const feedstockTileKey = 'oldWorld|zzz_feedstock|0|0';
      const feedstockUnitId = 'e_feedstock';

      // Enough draining explorers to exhaust the 64-probe shared budget
      // (4 probes each) before the feedstock Explorer (placed last) is
      // reached. 30 × 4 = 120 ≫ 64, leaving the budget at zero.
      const drainerCount = 30;

      Game buildGame({bool feedstockAlreadyProspected = false}) {
        final drainProvince = Province(
          id: drainProvinceId,
          regionId: ow,
          ownerId: playerId,
        );
        final feedstockProvince = Province(
          id: feedstockProvinceId,
          regionId: ow,
          ownerId: playerId,
        );

        final drainerProvinces = <Province>[];
        final units = <Unit>[];
        final tileKeysByRegion = <String, List<String>>{};
        final visibility = <String, String>{};
        final resourceByTile = <String, String>{};

        // Remote drain province: four fogged unprospected iron tiles.
        for (final tk in drainTiles) {
          visibility[tk] = 'fogged';
          resourceByTile[tk] = 'iron';
        }

        // Draining explorers, each in its own empty province (no tiles, no
        // visibility) so its own-province probe contributes nothing; the
        // shared budget is drained via the remote `aaa_drain` province. These
        // are inserted *before* the feedstock Explorer so they consume the
        // budget first (ownUnits preserves insertion order).
        for (var i = 0; i < drainerCount; i++) {
          final provId = 'oldWorld|d${i.toString().padLeft(2, '0')}';
          drainerProvinces.add(
            Province(id: provId, regionId: ow, ownerId: playerId),
          );
          units.add(
            Unit(
              id: 'drain_${i.toString().padLeft(2, '0')}',
              type: kUnitTypeExplorer,
              ownerId: playerId,
              locationProvinceId: provId,
            ),
          );
        }

        // Feedstock Explorer, co-located with its owned unprospected iron tile,
        // inserted last so the shared budget is already exhausted.
        visibility[feedstockTileKey] = 'fogged';
        resourceByTile[feedstockTileKey] = 'iron';
        units.add(
          Unit(
            id: feedstockUnitId,
            type: kUnitTypeExplorer,
            ownerId: playerId,
            locationProvinceId: feedstockProvinceId,
          ),
        );

        for (final p in drainerProvinces) {
          tileKeysByRegion[p.id] = const <String>[];
        }
        tileKeysByRegion[drainProvinceId] = List<String>.from(drainTiles);
        tileKeysByRegion[feedstockProvinceId] = const [feedstockTileKey];

        final prospected = <String>{
          if (feedstockAlreadyProspected) feedstockTileKey,
        };

        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              ...drainerProvinces,
              drainProvince,
              feedstockProvince,
            ],
            units: units,
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: {playerId: visibility},
          playerProspectedTiles: {playerId: prospected},
          resourceByTileKey: resourceByTile,
          tileKeysByRegionAndProvince: {ow: tileKeysByRegion},
        );
        return Game(
          id: 'g',
          worldState: world,
          players: const [
            Player(id: playerId, displayName: 'GP', isHuman: false),
          ],
        );
      }

      MapTopology topologyFor(Game game) {
        return MapTopology(
          nodes: [
            for (final p in game.worldState.oldWorld.provinces)
              TopologyNode(
                id: ProvinceId.localIdFrom(p.id),
                regionId: ow,
                type: TopologyNodeType.province,
              ),
          ],
          edges: const [],
        );
      }

      List<WorkOrder> feedstockProspects(List<WorkOrder> suggestions) =>
          suggestions
              .where(
                (o) =>
                    o.unitId == feedstockUnitId &&
                    o.target == kWorkTargetProspect,
              )
              .toList();

      test(
        'co-located feedstock Explorer still receives its iron prospect '
        'after earlier units drain the shared probe budget',
        () {
          final game = buildGame();
          final topology = topologyFor(game);
          final view = buildPlayerView(game, topology, playerId);
          final suggestions = suggestWorkOrders(
            view,
            game,
            topology,
            const Orders(),
          );
          final prospects = feedstockProspects(suggestions);
          expect(prospects, isNotEmpty);
          expect(
            prospects.map((o) => o.targetTileKey),
            contains(feedstockTileKey),
          );
        },
      );

      test(
        'no feedstock prospect when the co-located tile is already prospected '
        '(negative control)',
        () {
          final game = buildGame(feedstockAlreadyProspected: true);
          final topology = topologyFor(game);
          final view = buildPlayerView(game, topology, playerId);
          final suggestions = suggestWorkOrders(
            view,
            game,
            topology,
            const Orders(),
          );
          expect(feedstockProspects(suggestions), isEmpty);
        },
      );

      test('own-province budget exemption is deterministic across runs', () {
        final game = buildGame();
        final topology = topologyFor(game);
        final view = buildPlayerView(game, topology, playerId);
        final first = suggestWorkOrders(view, game, topology, const Orders());
        final second = suggestWorkOrders(view, game, topology, const Orders());
        List<String> keyOf(List<WorkOrder> os) =>
            (os.map((o) => '${o.unitId}|${o.target}|${o.targetTileKey}').toList()
              ..sort());
        expect(keyOf(first), equals(keyOf(second)));
        expect(feedstockProspects(first), isNotEmpty);
      });
    },
  );
}
