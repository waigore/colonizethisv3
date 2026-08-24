// Pins the host-level Explore-with-explorer *shortcut-assignment* tap flow for
// both province detail hosts (`GameMapProvinceDetailSidePanel` wide,
// `GameMapNarrowDetailOverlaySlot` narrow).
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
// § Tile inline actions:
//   - "Given the user taps an enabled `Explore with explorer` and click-time
//      state remains valid, when the explorer shortcut assign is triggered,
//      then the system commits a pending `WorkOrder(target: explore,
//      targetTileKey: <exact selected tile key>)` and The UI layer does not
//      enter generic work-target selection mode."
//   - "Given the user taps `Explore with explorer` and click-time state drift
//      has invalidated assignment, when the tap fires, then The UI layer
//      performs a silent no-op and the system commits no pending work order."
//
// Coverage gap closed here (Refs #2865):
//   - `province_overlay_tile_inline_action_non_clickable_test.dart` pins the
//     *overlay-level* callback contract (enabled fires / disabled does not).
//   - Neither asserts the *host wiring*: that tapping the enabled inline action
//     emits `OpenCivilianUnitsPanelEvent(explorerOnly: true,
//     exploreShortcutTargetTileKey: <exact tile key>)` on the app event bus.
//   - This file pins the positive path, the no-explorer negative, and the
//     click-time revalidation drift silent no-op.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'province_explore_shortcut_host_emit_event_test_support.dart';

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_province_explore_shortcut_emit');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  Future<List<OpenCivilianUnitsPanelEvent>> pumpHostAndSelect(
    WidgetTester tester, {
    required Game game,
    required ProvinceShortcutHostCase host,
    required PerPlayerWorkTargetSelectionCache cache,
  }) => pumpProvinceShortcutHostAndSelect(
    tester,
    gamesBox: gamesBox,
    gameService: provinceShortcutHostEmitGameService(
      gamesBox: gamesBox,
      gameId: kExploreShortcutGameId,
      combinedTopology: exploreShortcutCombinedTopology,
      tileMapByRegion: exploreShortcutTileMapByRegion,
      topologyByRegion: exploreShortcutTopologyByRegion,
    ),
    game: game,
    humanPlayerId: kExploreShortcutHumanPlayerId,
    host: host,
    region: exploreShortcutPartiallyRevealedRegion(),
    combinedTopology: exploreShortcutCombinedTopology,
    workTargetSelectionCache: cache,
    selectedTileKey: kExploreShortcutTileKey,
  );

  Future<void> expectExploreShortcutEmits(
    WidgetTester tester, {
    required List<OpenCivilianUnitsPanelEvent> opened,
    required String hostLabel,
  }) async {
    final shortcut = exploreShortcutAction(enabled: true);
    expect(
      shortcut,
      findsOneWidget,
      reason:
          '$hostLabel must render an enabled Explore inline action for a '
          'partially revealed province with an explorer and a cached '
          'explore-eligible target.',
    );
    await tester.ensureVisible(shortcut);
    await tester.tap(shortcut);
    await tester.pump();
    expect(opened, hasLength(1));
    final event = opened.single;
    expect(event.explorerOnly, isTrue);
    expect(event.builderOnly, isFalse);
    expect(event.exploreShortcutTargetTileKey, kExploreShortcutTileKey);
    expect(event.buildImprovementShortcutTargetTileKey, isNull);
    expect(event.prospectShortcutTargetTileKey, isNull);
  }

  for (final host in provinceShortcutHostCases) {
    testWidgets(
      '${host.wide ? 'wide' : 'narrow'} host: tapping the enabled Explore '
      'shortcut emits an explorer-only OpenCivilianUnitsPanelEvent targeting '
      'the exact selected tile key '
      '(SPEC § Tile inline actions — Explore shortcut assignment)',
      (WidgetTester tester) async {
        final opened = await pumpHostAndSelect(
          tester,
          game: buildExploreShortcutGame(withExplorer: true),
          host: host,
          cache: exploreShortcutCache(),
        );
        await expectExploreShortcutEmits(
          tester,
          opened: opened,
          hostLabel: host.label,
        );
      },
    );

    testWidgets(
      'negative — ${host.wide ? 'wide' : 'narrow'} host with no Explorer unit '
      'does not enable Explore and emits no OpenCivilianUnitsPanelEvent',
      (WidgetTester tester) async {
        final opened = await pumpHostAndSelect(
          tester,
          game: buildExploreShortcutGame(withExplorer: false),
          host: host,
          cache: exploreShortcutCache(),
        );
        expect(exploreShortcutAction(enabled: true), findsNothing);
        if (host.wide) {
          final anyShortcut = find.byWidgetPredicate(
            (Widget w) => w is CtIconAction && w.icon == Icons.explore,
          );
          if (anyShortcut.evaluate().isNotEmpty) {
            await tester.tap(anyShortcut.first, warnIfMissed: false);
            await tester.pump();
          }
        }
        expect(opened, isEmpty);
      },
    );
  }

  testWidgets(
    'negative — click-time drift invalidates explore assignment and the tap '
    'is a silent no-op on the event bus (SPEC § Tile inline actions)',
    (WidgetTester tester) async {
      final game = buildExploreShortcutGame(withExplorer: true);
      final driftCache = ExploreDriftWorkTargetCache()
        ..refresh(
          WorkTargetSelectionSnapshot(
            game: game,
            playerId: kExploreShortcutHumanPlayerId,
            playerView: buildPlayerView(
              game,
              exploreShortcutCombinedTopology,
              kExploreShortcutHumanPlayerId,
            ),
            topology: exploreShortcutCombinedTopology,
            currentOrders: const Orders(),
            tileMapByRegion: exploreShortcutTileMapByRegion,
          ),
        );

      final opened = await pumpHostAndSelect(
        tester,
        game: game,
        host: provinceShortcutHostCases.first,
        cache: driftCache,
      );

      final shortcut = exploreShortcutAction(enabled: true);
      expect(shortcut, findsOneWidget);
      driftCache.armExploreDriftOnNextRead();
      await tester.ensureVisible(shortcut);
      await tester.tap(shortcut);
      await tester.pump();
      expect(
        opened,
        isEmpty,
        reason:
            'When click-time revalidation finds explore no longer enabled, '
            'the host must not emit OpenCivilianUnitsPanelEvent.',
      );
    },
  );
}
