// Widget goldens for Players bar toggle chrome (Refs #3898 / #4720 Slice G).
// Pixel baselines live under `app/test/goldens/`.
// SPEC: `SPEC/ui/empire-overview.md` § Players bar toggle.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'golden_capture_harness.dart';

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart'
    show kPlayersBarToggleButtonKey;
import 'package:colonizethis_app/features/game/widgets/shell/players_bar_toggle_button.dart';

Widget _goldenHost({
  required Key boundaryKey,
  required Widget child,
  Size? surfaceSize,
}) {
  return wrapGoldenBoundary(
    boundaryKey: boundaryKey,
    includeLocalizations: true,
    scaffoldBackgroundColor: AppThemes.editorialMonocle.scaffoldBackgroundColor,
    child: surfaceSize == null
        ? child
        : SizedBox(
            width: surfaceSize.width,
            height: surfaceSize.height,
            child: child,
          ),
  );
}

void main() {
  suppressLogsForTests();

  testWidgets('golden: players bar toggle chrome on and off (Refs #3898)', (
    WidgetTester tester,
  ) async {
    const onBoundaryKey = ValueKey<String>('players_bar_toggle_on');
    const offBoundaryKey = ValueKey<String>('players_bar_toggle_off');

    await tester.pumpWidget(
      _goldenHost(
        boundaryKey: onBoundaryKey,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PlayersBarToggleButton(
                tooltip: 'Show players bar',
                showPlayersBar: true,
                onPressed: () {},
              ),
              const SizedBox(width: 8),
              PlayersBarToggleButton(
                tooltip: 'Hide players bar',
                showPlayersBar: false,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await pumpForGolden(tester, settle: false);

    expect(find.byKey(kPlayersBarToggleButtonKey), findsNWidgets(2));

    await expectLater(
      find.byKey(onBoundaryKey),
      matchesGoldenFile('goldens/players_bar_toggle_on_off.png'),
    );

    // Re-pump off-only surface for a dedicated inactive-state baseline.
    await tester.pumpWidget(
      _goldenHost(
        boundaryKey: offBoundaryKey,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: PlayersBarToggleButton(
            tooltip: 'Hide players bar',
            showPlayersBar: false,
            onPressed: () {},
          ),
        ),
      ),
    );
    await pumpForGolden(tester, settle: false);

    await expectLater(
      find.byKey(offBoundaryKey),
      matchesGoldenFile('goldens/players_bar_toggle_off.png'),
    );
  });
}
