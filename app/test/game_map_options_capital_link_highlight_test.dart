// Pins Refs #4370 capital-link disconnected highlight map-options toggle.

import 'package:colonizethis_app/features/game/widgets/dialogs/game_map_options_dialog.dart';
import 'package:colonizethis_app/widgets/ct_toggle_switch.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

void main() {
  suppressLogsForTests();

  testWidgets('AC: capital-link highlight toggle defaults ON and persists off', (
    tester,
  ) async {
    MapViewState? latest;
    await tester.pumpWidget(
      buildAppShell(
        child: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => GameMapOptionsDialog(
                      initialState: const MapViewState(),
                      onChanged: (s) => latest = s,
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Highlight land not bound to the capital'), findsOneWidget);
    expect(find.byType(CtToggleSwitch), findsNWidgets(4));

    await tester.tap(
      find.byKey(kGameMapOptionsShowCapitalLinkDisconnectedToggleKey),
    );
    await tester.pump();
    expect(latest?.showCapitalLinkDisconnectedHighlight, isFalse);
  });

  test('MapViewState missing JSON field defaults highlight ON', () {
    final state = MapViewState.fromJson(const {
      'zoomMultiplier': 1.0,
      'showProvinceOverlay': true,
      'showProvinceOwnershipTint': false,
      'showProvinceNamesLayer': true,
    });
    expect(state.showCapitalLinkDisconnectedHighlight, isTrue);
  });
}
