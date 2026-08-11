// Guards Development panel projection memoization across unrelated rebuilds (Refs #4175 Slice E).

import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show CtMapVisibilityMode;
import 'package:colonizethis_app/features/game/screens/development/development_screen_body.dart';
import 'package:colonizethis_app/features/game/widgets/shell/shell_player_context.dart';
import 'package:colonizethis_app/providers/development_panel_projection_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';
import 'development_panel_test_support.dart';
import 'panel_fixtures/core.dart';

class _RebuildTickHost extends StatefulWidget {
  const _RebuildTickHost({super.key, required this.child});

  final Widget child;

  @override
  State<_RebuildTickHost> createState() => _RebuildTickHostState();
}

class _RebuildTickHostState extends State<_RebuildTickHost> {
  var _tick = 0;

  void bump() => setState(() => _tick++);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('tick:$_tick', key: const Key('rebuild_tick')),
        Expanded(child: widget.child),
      ],
    );
  }
}

List<Override> _developmentOverrides(Game game, Box<dynamic> gamesBox) => [
  gamesBoxProvider.overrideWith((ref) => gamesBox),
  gameServiceProvider.overrideWith(
    (ref) => DevelopmentPanelMapGameService(gamesBox, GameSaveAdapter()),
  ),
  currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
  currentOrdersProvider.overrideWith(() => CurrentOrdersNotifier(const Orders())),
  shellPlayerContextProvider.overrideWithValue(
    const ShellPlayerContext(
      effectiveHumanPlayerId: kPanelTestHumanPlayerId,
      viewingPlayerId: kPanelTestHumanPlayerId,
      mapVisibilityMode: CtMapVisibilityMode.playerConstrained,
      playerView: null,
      omniscientDetail: false,
      showPlayerChrome: true,
      canMutateViaUi: true,
      debugCommandTargetPlayerId: kPanelTestHumanPlayerId,
      inObservePhase: false,
      observeBannerLabel: null,
      treasuryNotDefined: false,
      cargoNotDefined: false,
    ),
  ),
];

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    gamesBox = await openDevelopmentPanelTestHiveBox();
  });

  tearDownAll(() async {
    await gamesBox.close();
  });

  testWidgets(
    'developmentPanelProjectionProvider survives unrelated parent rebuilds (Refs #4175 Slice E)',
    (WidgetTester tester) async {
      final game = buildDevelopmentPanelGoldenGame();
      final container = ProviderContainer(
        overrides: _developmentOverrides(game, gamesBox),
      );
      addTearDown(container.dispose);

      var projectionNotifications = 0;
      container.listen(
        developmentPanelProjectionProvider,
        (_, _) => projectionNotifications++,
        fireImmediately: true,
      );

      final hostKey = GlobalKey<_RebuildTickHostState>();
      await tester.pumpWidget(
        buildAppShellWithContainer(
          container: container,
          child: _RebuildTickHost(
            key: hostKey,
            child: DevelopmentScreenBody(
              game: game,
              humanPlayerId: kPanelTestHumanPlayerId,
            ),
          ),
          localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          viewport: const Size(900, 760),
        ),
      );

      await pumpDevelopmentPanelReady(tester);

      final projectionAfterOpen = container.read(developmentPanelProjectionProvider);
      expect(projectionAfterOpen, isNotNull);
      final notificationsAfterOpen = projectionNotifications;

      hostKey.currentState!.bump();
      await tester.pump();

      final projectionAfterBump = container.read(developmentPanelProjectionProvider);
      expect(identical(projectionAfterOpen, projectionAfterBump), isTrue);
      expect(projectionNotifications, notificationsAfterOpen);
    },
  );
}
