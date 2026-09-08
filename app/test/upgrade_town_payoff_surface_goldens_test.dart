// Pixel goldens for MAP30001 / UNIT10001 Upgrade town payoff (Refs #4747).

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/map_radial/tile_context_radial.dart';
import 'package:colonizethis_app/features/game/widgets/map_radial/tile_radial_catalog.dart';
import 'package:colonizethis_app/features/game/widgets/map_radial/tile_radial_spoke_view.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/civilian_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/upgrade_town_payoff_gist_line.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';
import 'upgrade_town_payoff_test_support.dart';

const _pauseGist =
    'After this work: town workshops pause until level 4 · Takes 1 turn';

void main() {
  suppressLogsForTests();
  final l10n = AppLocalizationsEn();

  testWidgets('golden: MAP30001 2→3 pause gist (Refs #4747)', (tester) async {
    const boundaryKey = ValueKey<String>('upgrade_town_radial_pause');
    await pumpGoldenHost(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: const Size(400, 400),
      includeLocalizations: true,
      child: SizedBox(
        width: 400,
        height: 400,
        child: TileContextRadial(
          placeLine: 'Place: Alpha',
          wedges: const [
            TileRadialSpokeView(
              action: TileRadialCatalogAction.upgradeTown,
              enabled: true,
              label: 'Upgrade town',
              tooltip: 'Upgrade town',
              caption: _pauseGist,
            ),
          ],
          onWedge: (_) {},
          onMore: () {},
          onDismiss: () {},
          anchor: const Offset(200, 200),
        ),
      ),
    );
    expect(find.byKey(kUpgradeTownPayoffGistKey), findsOneWidget);
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/upgrade_town_payoff_radial_pause.png'),
    );
  });

  testWidgets('golden: UNIT10001 pending upgrade_town (Refs #4747)', (
    tester,
  ) async {
    const boundaryKey = ValueKey<String>('upgrade_town_pending_row');
    expect(l10n.provinceOverlay_upgradeTownPayoffGistPause('', 1), _pauseGist);
    await pumpGoldenHost(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: const Size(440, 820),
      includeLocalizations: true,
      wrapInProviderScope: true,
      scaffoldBackgroundColor:
          AppThemes.editorialMonocle.scaffoldBackgroundColor,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 760),
        child: CivilianUnitsPanel(
          game: upgradeTownPayoffPanelGame(id: 'g_ut_pending_golden'),
          humanPlayerId: upgradeTownPayoffHumanId,
          bus: AppEventBus.create(),
          currentOrders: upgradeTownPayoffPendingOrders(),
          builderOnly: true,
        ),
      ),
    );
    expect(find.byKey(kUpgradeTownPayoffGistKey), findsOneWidget);
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/upgrade_town_payoff_pending_row.png'),
    );
  });
}
