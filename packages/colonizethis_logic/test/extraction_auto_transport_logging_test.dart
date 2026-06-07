import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

import 'extraction_auto_transport_test_fixtures.dart';

List<String> _autoTransportMessages(List<LogEvent> events) => [
  for (final e in events)
    if (e.message.contains('economy: extraction auto_transport')) e.message,
];

void main() {
  group('extraction auto-transport logging', () {
    late List<LogEvent> capturedEvents;
    late void Function(LogEvent) listener;

    setUp(() {
      capturedEvents = [];
      listener = capturedEvents.add;
      Logger.addLogListener(listener);
      Logger.level = Level.debug;
    });

    tearDown(() {
      Logger.removeLogListener(listener);
      capturedEvents.clear();
      Logger.level = Level.off;
    });

    test(
      'resolveTurnForGame emits land, overseas cargo_cap, and interception lines',
      () {
        const globalSeed = 42;
        final enemyPatrol = Fleet(
          id: 'f_p2_patrol',
          ownerId: 'p2',
          seaZoneId: 'sea1',
          regionId: 'oldWorld',
          shipTypeIds: const ['sloop'],
          mission: FleetMission.patrol,
        );
        final nwGrid = [
          [Resource.sugarCane, Resource.sugarCane],
          [Resource.sugarCane, Resource.sugarCane],
        ];
        final (:game, :tileMapByRegion) = extractionAutoTransportFixture(
          nwResourceGrid: nwGrid,
          nwImprovementLevel: 1,
          extraFleets: [enemyPatrol],
          globalGameSeed: globalSeed,
          relationWithP2: RelationState.atWar,
        );
        final topology = crossRegionSeaTopologyForExtractionTests();

        requireTurnResolutionComplete(
          resolveTurnForGame(
            game: game,
            topology: topology,
            orders: const Orders(),
            tileMapByRegion: tileMapByRegion,
            defaultAssignments: const [],
          ),
        );

        final lines = _autoTransportMessages(capturedEvents);
        expect(
          lines.any((m) => m.contains('extraction auto_transport land')),
          isTrue,
        );
        expect(
          lines.any((m) => m.contains('extraction auto_transport overseas')),
          isTrue,
        );
        expect(
          lines.any(
            (m) => m.contains('extraction auto_transport interception'),
          ),
          isTrue,
        );
      },
    );
  });
}
