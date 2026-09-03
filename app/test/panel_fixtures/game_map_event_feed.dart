// Shared lightweight, hand-built [Game] fixtures for app panel widget tests.
//
// Split into focused modules under `panel_fixtures/`; import via
// `panel_test_fixtures.dart` barrel (Refs #3847).

import 'package:colonizethis_models/colonizethis_models.dart';

import 'core.dart';

/// Lightweight game shaped for the `game_map_area_event_feed_test` suite, which
/// mounts a full `GameMapArea` and asserts only on the player-turn event-feed
/// chrome driven by `AppEventBus` events (Refs #3656).
///
/// Every feed line is produced from the emitted event payload, not generated
/// map data (`game_map_area_turn_feed.dart`): research/diplomacy/discovery lines
/// read only player display names, the work-completed line locates the tile key
/// carried by the event, and the naval-battle line resolves its locate tile via
/// `portsByProvinceSeaboard` (`tileKeyForSeaZoneLocation`) when no
/// `gameServiceProvider` map data is registered — so a port-seaboard entry is
/// the only map-shaped data needed.
///
/// The fixture provides:
/// - the human ([kPanelTestHumanPlayerId]) plus one AI great power (`gp2`), both
///   with display names, so `firstWhere((p) => p.isHuman)`, the opponent
///   `firstWhere((p) => p.id != humanId)`, and the diplomacy war-copy name
///   lookups all resolve;
/// - one old-world Explorer civilian so the dispose test's
///   `oldWorld.units.first.id` sample unit exists;
/// - a single `portsByProvinceSeaboard` entry mapping the `sz0` seaboard to a
///   port tile, so the naval feed line resolves a non-empty anchor tile key
///   (`oldWorld|sz0` → `oldWorld|cap|0|0`) while an unknown sea zone stays
///   unresolved (the non-tappable-anchor case).
Game buildMapAreaEventFeedTestGame() {
  const human = kPanelTestHumanPlayerId;
  const capProvince = 'oldWorld|cap';
  const seaZoneId = 'sz0';
  return buildPanelTestGame(
    id: 'map-area-event-feed-widget-test',
    players: const [
      Player(id: human, displayName: 'Test Human', isHuman: true),
      Player(id: 'gp2', displayName: 'Rival Power', isHuman: false),
    ],
    // The province is intentionally left unowned: the event-feed suite mounts
    // the players bar, whose per-player score chip renders the owned-province
    // count. Owning exactly one province here would render a "1" chip that
    // collides with the news-feed badge's "1" count
    // (`find.text('1')` findsOneWidget).
    oldWorldProvinces: const [
      Province(
        id: capProvince,
        regionId: 'oldWorld',
        displayName: 'Capital',
        townTileKey: 'oldWorld|cap|0|0',
      ),
    ],
    oldWorldUnits: [
      Unit(
        id: 'civ_explorer',
        type: kUnitTypeExplorer,
        ownerId: human,
        locationProvinceId: capProvince,
        tileKey: 'oldWorld|cap|0|0',
      ),
    ],
    portsByProvinceSeaboard: const {
      'oldWorld|cap|$seaZoneId': 'oldWorld|cap|0|0',
    },
    seaZoneDisplayNameById: const {'oldWorld|$seaZoneId': 'Northern Sea'},
  );
}

/// Lightweight game shaped for the `player_turn_event_feed_narrow_inset_test`
/// suite, which mounts a full **narrow** `GameMapArea` purely to assert the
/// floating `PlayerTurnEventFeedCard`'s `Positioned.right` inset contract
/// (Refs #2870 S3 / Req 11, Refs #3656).
///
/// The suite (a) toggles `mapViewState.showPlayerTurnEventsFeed` on via
/// `copyWith` so the narrow feed card mounts, and (b) opens the province bottom
/// sheet by feeding `mapProvincePanelProvider.reportMapTileTapped` a tile key
/// pulled from `tileKeysByRegionAndProvince['oldWorld']`. The narrow inset
/// contract is independent of generated map/topology data: the feed card sits
/// at `kMapOverlayEdgeInset` whether the province panel is open or closed (the
/// narrow code path never applies the wide `gameMapWideOverlayRightInset`), and
/// `reportMapTileTapped` only stores the tapped tile key (no province geometry
/// lookup — see `map_province_panel_provider.dart`).
///
/// The fixture therefore provides a single human ([kPanelTestHumanPlayerId])
/// owning one old-world province whose `tileKeysByRegionAndProvince` entry
/// supplies the `_firstOldWorldTileKey` the suite taps; that tile key maps back
/// to the seeded province so the opened narrow province overlay resolves real
/// (if minimal) province data rather than an unknown id. Pair it with
/// `buildLightweightMapViewData()` so the canvas mounts without the ~7-11s
/// `getDebugInitGameResult()` map generation.
Game buildEventFeedNarrowInsetTestGame() {
  const human = kPanelTestHumanPlayerId;
  const capProvince = 'oldWorld|cap';
  return buildPanelTestGame(
    id: 'event-feed-narrow-inset-widget-test',
    oldWorldProvinces: const [
      Province(
        id: capProvince,
        regionId: 'oldWorld',
        ownerId: human,
        displayName: 'Capital',
        townTileKey: 'oldWorld|cap|0|0',
      ),
    ],
    tileKeysByRegionAndProvince: const {
      'oldWorld': {
        capProvince: ['oldWorld|cap|0|0'],
      },
    },
  );
}
