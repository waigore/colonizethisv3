// Shared harness and pump helpers for `game_map_area_event_feed_*` suites
// (Refs #4146, #4305 — keeps event-feed widget tests under the 500-line gate).

import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/features/game/flame/map_state/map_state.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart'
    show kPlayerTurnFeedToggleButtonKey;
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/debug_console_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/map_view_provider.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';
import 'map_view_test_fixtures.dart';
import 'panel_test_fixtures.dart';

class MapAreaHost extends StatefulWidget {
  const MapAreaHost({super.key, required this.game, required this.mapViewData});

  final Game game;
  final InitGameMapViewData mapViewData;

  @override
  State<MapAreaHost> createState() => _MapAreaHostState();
}

class _MapAreaHostState extends State<MapAreaHost> {
  bool _showMapArea = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextButton(
            onPressed: () => setState(() => _showMapArea = false),
            child: const Text('dispose-map-area'),
          ),
          Expanded(
            child: _showMapArea
                ? GameMapArea(
                    game: widget.game,
                    mapViewData: widget.mapViewData,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class EventFeedHarness {
  EventFeedHarness(this.game, this.mapViewData, this.bus)
    : humanId = game.players.firstWhere((p) => p.isHuman).id {
    opponentId = game.players.firstWhere((p) => p.id != humanId).id;
  }

  final Game game;
  final InitGameMapViewData mapViewData;
  final AppEventBus bus;
  final String humanId;
  late final String opponentId;

  String get playerDisplayName =>
      game.players.firstWhere((p) => p.id == humanId).displayName;

  String get opponentDisplayName =>
      game.players.firstWhere((p) => p.id == opponentId).displayName;
}

EventFeedHarness newEventFeedHarness({bool disposeBus = true}) {
  final harness = EventFeedHarness(
    buildMapAreaEventFeedTestGame(),
    buildLightweightMapViewData(),
    AppEventBus.create(),
  );
  if (disposeBus) {
    addTearDown(harness.bus.dispose);
  }
  return harness;
}

Future<void> pumpEventFeedMapArea(
  WidgetTester tester, {
  required Box<dynamic> gamesBox,
  required EventFeedHarness harness,
  Widget? home,
  bool debugConsoleEnabled = false,
  Size? mediaQuerySize,
}) async {
  // Editorial shell via buildAppShell (Refs #4035 — no inline MaterialApp).
  await tester.pumpWidget(
    buildAppShell(
      overrides: [
        appEventBusProvider.overrideWith((ref) => harness.bus),
        currentGameProvider.overrideWith(
          () => CurrentGameNotifier(harness.game),
        ),
        gamesBoxProvider.overrideWith((ref) => gamesBox),
        gameServiceProvider.overrideWith(
          (ref) => GameService(gamesBox, GameSaveAdapter()),
        ),
        currentOrdersProvider.overrideWith(
          () => CurrentOrdersNotifier(const Orders()),
        ),
        mapViewDataProvider.overrideWith((ref) => harness.mapViewData),
        if (debugConsoleEnabled)
          debugConsoleEnabledProvider.overrideWithValue(true),
      ],
      viewport: mediaQuerySize,
      child:
          home ??
          Scaffold(
            body: GameMapArea(
              game: harness.game,
              mapViewData: harness.mapViewData,
            ),
          ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

Future<void> commitEventFeedTurnEvents(
  WidgetTester tester,
  EventFeedHarness harness,
  List<AppEvent> events, {
  required int turnNumber,
  bool openFeed = true,
}) async {
  for (final event in events) {
    harness.bus.emit(event);
  }
  // Digest marks that DLG50001 will show, so last-turn playback stays gated
  // (SPEC/ui/map-widget.md). Feed suites do not close news; omitting digest
  // starts pulses immediately and duplicates spatial captions in finders.
  harness.bus.emit(
    TurnResolutionCompleteEvent(
      gameId: harness.game.id,
      turnNumber: turnNumber,
      turnNewsDigest: TurnNewsDigest(
        resolvedTurnNumber: turnNumber,
        lines: const [],
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
  if (openFeed) {
    await tester.tap(find.byKey(kPlayerTurnFeedToggleButtonKey));
    await tester.pump();
  }
}

List<LocateMapTileEvent> listenEventFeedLocateEvents(EventFeedHarness harness) {
  final locateEvents = <LocateMapTileEvent>[];
  final sub = harness.bus.on<LocateMapTileEvent>().listen(locateEvents.add);
  addTearDown(() async {
    await sub.cancel();
    harness.bus.dispose();
  });
  return locateEvents;
}

List<NavigateToRouteEvent> listenEventFeedNavigateEvents(
  EventFeedHarness harness,
) {
  final navigateEvents = <NavigateToRouteEvent>[];
  final sub = harness.bus.on<NavigateToRouteEvent>().listen(navigateEvents.add);
  addTearDown(() async {
    await sub.cancel();
    harness.bus.dispose();
  });
  return navigateEvents;
}

List<OpenMapTileDetailEvent> listenEventFeedOpenMapTileDetailEvents(
  EventFeedHarness harness,
) {
  final events = <OpenMapTileDetailEvent>[];
  final sub = harness.bus.on<OpenMapTileDetailEvent>().listen(events.add);
  addTearDown(() async {
    await sub.cancel();
    harness.bus.dispose();
  });
  return events;
}

List<OpenCivilianUnitsPanelEvent> listenEventFeedOpenCivilianPanelEvents(
  EventFeedHarness harness,
) {
  final events = <OpenCivilianUnitsPanelEvent>[];
  final sub = harness.bus.on<OpenCivilianUnitsPanelEvent>().listen(events.add);
  addTearDown(() async {
    await sub.cancel();
    harness.bus.dispose();
  });
  return events;
}

Future<void> openEventFeedToggle(WidgetTester tester) async {
  await tester.tap(find.byKey(kPlayerTurnFeedToggleButtonKey));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

