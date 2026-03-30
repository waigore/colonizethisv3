import 'package:colonizethis_app/features/game/flame/game_map_area.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _MapAreaHost extends StatefulWidget {
  const _MapAreaHost({required this.game, required this.mapViewData});

  final Game game;
  final InitGameMapViewData mapViewData;

  @override
  State<_MapAreaHost> createState() => _MapAreaHostState();
}

class _MapAreaHostState extends State<_MapAreaHost> {
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
                ? GameMapArea(game: widget.game, mapViewData: widget.mapViewData)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

void main() {
  suppressLogsForTests();

  testWidgets('GameMapArea dispose cancels AppEventBus subscriptions', (
    WidgetTester tester,
  ) async {
    final init = getDebugInitGameResult();
    final game = init.game;
    final mapViewData = init.mapViewData;
    final bus = AppEventBus.create();
    final sampleUnitId = game.worldState.oldWorld.units.isNotEmpty
        ? game.worldState.oldWorld.units.first.id
        : game.worldState.newWorld.units.isNotEmpty
        ? game.worldState.newWorld.units.first.id
        : 'missing-unit-id';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appEventBusProvider.overrideWith((ref) {
            return bus;
          }),
          currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
        ],
        child: MaterialApp(
          home: _MapAreaHost(game: game, mapViewData: mapViewData),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('dispose-map-area'));
    await tester.pumpAndSettle();

    bus.emit(
      const LocateMapTileEvent(
        tileKey: 'oldWorld|dummy|0|0',
        regionId: 'oldWorld',
      ),
    );
    bus.emit(
      StartCivilianWorkTargetSelectionEvent(
        unitId: sampleUnitId,
        workTarget: 'explore',
      ),
    );
    bus.emit(const UnitsPanelClosedEvent('civilian'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    bus.dispose();
  });
}
