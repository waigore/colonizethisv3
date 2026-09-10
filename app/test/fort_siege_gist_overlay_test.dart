// MAP20001 Military fort siege gist (Refs #4764).
// SPEC/ui/province-sea-zone-detail-overlay.md § Fort siege gist.

import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_military_section.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/build_fort_payoff_gist_line.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
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

  testWidgets(
    'siege gist shows when build-fort gist is hidden (observe / no mutate)',
    (tester) async {
      final l10n = AppLocalizationsEn();
      final game = fortSiegeOverlayGame(fortLevel: 2);
      await tester.pumpWidget(
        buildAppShell(
          localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          child: Material(
            child: buildMilitarySectionByOwner(
              l10n: l10n,
              game: game,
              military: const [],
              humanPlayerId: kFortSiegeOverlayHumanId,
              provinceId: kFortSiegeOverlayProvinceId,
              draftOrders: const Orders(),
              fortLevel: 2,
              showBuildFortActionIcon: false,
              buildFortActionEnabled: false,
              buildFortTooltip: '',
              buildFortPayoffGist: null,
            ),
          ),
        ),
      );
      expect(find.textContaining('Stone fort siege'), findsOneWidget);
      expect(
        find.text(
          'Medium walls soak more of the attack; the defender has 2 extra guns.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(kBuildFortPayoffGistKey), findsNothing);
    },
  );

  testWidgets('unknown military intel omits siege gist', (tester) async {
    final game = fortSiegeOverlayGame(
      fortLevel: 1,
      ownerId: kFortSiegeOverlayRivalId,
      tileVisibility: 'unrevealed',
    );
    await pumpProvinceOverlayAtDarkTheme(
      tester,
      game: game,
      displayId: kFortSiegeOverlayProvinceId,
      region: fortSiegeOverlayRegion(ownerFactionId: kFortSiegeOverlayRivalId),
      selectedTileKey: kFortSiegeOverlayTileKey,
      humanPlayerId: kFortSiegeOverlayHumanId,
      playerView: demoOverlayPlayerView(game),
      omniscientDetail: false,
      shellWidth: 460,
    );
    expect(find.text('???'), findsWidgets);
    expect(find.textContaining('walls soak'), findsNothing);
    expect(find.textContaining('Wood fort siege'), findsNothing);
  });
}
