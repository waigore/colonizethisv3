// MAP20001 Military fort siege gist (Refs #4764).
// SPEC/ui/province-sea-zone-detail-overlay.md § Fort siege gist.

import 'package:colonizethis_app/features/game/widgets/units/civilian/build_fort_payoff_gist_line.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'fort_siege_gist_overlay_test_support.dart';
import 'province_overlay_test_harness.dart';

void main() {
  suppressLogsForTests();

  testWidgets('full intel wood fort shows siege gist without build-fort gist', (
    tester,
  ) async {
    final game = fortSiegeOverlayGame(fortLevel: 1);
    await pumpProvinceOverlayAtDarkTheme(
      tester,
      game: game,
      displayId: kFortSiegeOverlayProvinceId,
      region: fortSiegeOverlayRegion(),
      selectedTileKey: kFortSiegeOverlayTileKey,
      humanPlayerId: kFortSiegeOverlayHumanId,
      playerView: demoOverlayPlayerView(game),
      omniscientDetail: true,
      shellWidth: 460,
    );
    expect(find.textContaining('Wood fort siege'), findsOneWidget);
    expect(
      find.text(
        'Light walls soak some of the attack; the defender has 1 extra gun.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(kBuildFortPayoffGistKey), findsNothing);
  });

  testWidgets('open field omits siege gist', (tester) async {
    final game = fortSiegeOverlayGame(fortLevel: 0);
    await pumpProvinceOverlayAtDarkTheme(
      tester,
      game: game,
      displayId: kFortSiegeOverlayProvinceId,
      region: fortSiegeOverlayRegion(),
      selectedTileKey: kFortSiegeOverlayTileKey,
      humanPlayerId: kFortSiegeOverlayHumanId,
      playerView: demoOverlayPlayerView(game),
      omniscientDetail: true,
      shellWidth: 460,
    );
    expect(find.textContaining('Open field'), findsOneWidget);
    expect(find.textContaining('walls soak'), findsNothing);
  });

  testWidgets('stone fort shows medium-walls gist in observe (no mutate)', (
    tester,
  ) async {
    final game = fortSiegeOverlayGame(fortLevel: 2);
    await pumpProvinceOverlayAtDarkTheme(
      tester,
      game: game,
      displayId: kFortSiegeOverlayProvinceId,
      region: fortSiegeOverlayRegion(),
      selectedTileKey: kFortSiegeOverlayTileKey,
      humanPlayerId: kFortSiegeOverlayHumanId,
      playerView: demoOverlayPlayerView(game),
      omniscientDetail: true,
      shellWidth: 460,
    );
    expect(find.textContaining('Stone fort siege'), findsOneWidget);
    expect(
      find.text(
        'Medium walls soak more of the attack; the defender has 2 extra guns.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(kBuildFortPayoffGistKey), findsNothing);
  });
}
