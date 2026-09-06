// Pins SPEC/ui/empire-overview.md § Map display options dialog toggle coupling
// (dark editorial-monocle chrome — Refs #2861 S8 / R9, Refs #2867 R1).

import 'package:colonizethis_app/features/game/widgets/dialogs/game_map_options_dialog.dart';
import 'package:colonizethis_app/widgets/ct_toggle_switch.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'game_map_options_dialog_test_support.dart';

void main() {
  suppressLogsForTests();

  group('GameMapOptionsDialog toggle coupling (Refs #2861 S8 / Refs #2867 R1)', () {
    testWidgets(
      'turning improvements off auto-offs roads and disables the roads switch',
      (WidgetTester tester) async {
        final List<MapViewState> emitted = <MapViewState>[];
        await tester.pumpWidget(
          gameMapOptionsDialogFrame(
            initialState: MapViewState.defaults,
            onChanged: emitted.add,
          ),
        );
        await openGameMapOptionsDialog(tester);

        await tester.tap(
          find.byKey(kGameMapOptionsShowMapImprovementsToggleKey),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(emitted, hasLength(1));
        expect(emitted.last.showMapImprovements, isFalse);
        expect(emitted.last.showMapRoads, isFalse);
        expect(emitted.last.showMapResources, isTrue);

        final roads = tester.widget<CtToggleSwitch>(
          find.byKey(kGameMapOptionsShowMapRoadsToggleKey),
        );
        expect(roads.value, isFalse);
        expect(roads.onChanged, isNull);

        await tester.tap(find.byKey(kGameMapOptionsShowMapRoadsToggleKey));
        await tester.pump();
        expect(emitted, hasLength(1));
      },
    );

    testWidgets(
      'turning improvements on leaves roads off until the player turns them on',
      (WidgetTester tester) async {
        final List<MapViewState> emitted = <MapViewState>[];
        await tester.pumpWidget(
          gameMapOptionsDialogFrame(
            initialState: const MapViewState(
              showMapImprovements: false,
              showMapRoads: false,
            ),
            onChanged: emitted.add,
          ),
        );
        await openGameMapOptionsDialog(tester);

        await tester.tap(
          find.byKey(kGameMapOptionsShowMapImprovementsToggleKey),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(emitted.last.showMapImprovements, isTrue);
        expect(emitted.last.showMapRoads, isFalse);
        final roads = tester.widget<CtToggleSwitch>(
          find.byKey(kGameMapOptionsShowMapRoadsToggleKey),
        );
        expect(roads.value, isFalse);
        expect(roads.onChanged, isNotNull);
      },
    );

    testWidgets(
      'turning resources off leaves improvements and roads unchanged',
      (WidgetTester tester) async {
        final List<MapViewState> emitted = <MapViewState>[];
        await tester.pumpWidget(
          gameMapOptionsDialogFrame(
            initialState: MapViewState.defaults,
            onChanged: emitted.add,
          ),
        );
        await openGameMapOptionsDialog(tester);

        await tester.tap(find.byKey(kGameMapOptionsShowMapResourcesToggleKey));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(emitted.last.showMapResources, isFalse);
        expect(emitted.last.showMapImprovements, isTrue);
        expect(emitted.last.showMapRoads, isTrue);
      },
    );
  });
}
