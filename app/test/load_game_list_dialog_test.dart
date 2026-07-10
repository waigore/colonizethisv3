import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/features/shell/save_load/load_game_list_dialog.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

class _LoadDialogGameService extends GameService {
  _LoadDialogGameService(super.box, super.adapter);

  List<LoadableSaveEntry> entries = const [];
  GameSaveSession? sessionToLoad;

  @override
  List<LoadableSaveEntry> listLoadableSaves() => entries;

  @override
  GameSaveSession? loadGameSession(String gameId) =>
      sessionToLoad != null && gameId == sessionToLoad!.game.id
          ? sessionToLoad
          : null;

  @override
  GameSaveSession? loadAutoSaveSession() =>
      sessionToLoad != null &&
          entries.any(
            (e) =>
                e.kind == LoadableSaveKind.autoSave &&
                e.storageId == kAutoSaveSlotId,
          )
      ? sessionToLoad
      : null;
}

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;
  late _LoadDialogGameService service;
  late AppEventBus bus;

  final loadedGame = Game(
    id: 'manual_a',
    worldState: const WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 9),
      oldWorld: RegionData(),
      newWorld: RegionData(),
    ),
    players: const [
      Player(id: 'gp1', displayName: 'Spain', isHuman: true),
    ],
  );

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_load_list_dialog');
    gamesBox = await Hive.openBox<dynamic>('${HiveBoxNames.games}_load_list');
  });

  setUp(() async {
    await gamesBox.clear();
    AppEventBus.reset();
    bus = AppEventBus.create();
    service = _LoadDialogGameService(gamesBox, GameSaveAdapter());
  });

  tearDown(() {
    bus.dispose();
  });

  Widget host({required bool fromPause, List<LoadableSaveEntry> entries = const []}) {
    service.entries = entries;
    service.sessionToLoad = GameSaveSession(
      game: loadedGame,
      draftOrders: const Orders(
        buildUnitOrdersByPlayerId: {
          'gp1': [
            BuildUnitOrder(
              unitType: 'peasant',
              isMilitary: false,
              spawnProvinceId: 'oldWorld|cap',
            ),
          ],
        },
      ),
      productionDesiredOutputByRecipe: const {'r1': 2},
      displayName: 'Spain Save',
    );
    return ProviderScope(
      overrides: [
        gamesBoxProvider.overrideWithValue(gamesBox),
        gameServiceProvider.overrideWith((ref) => service),
        appEventBusProvider.overrideWith((ref) => bus),
        currentGameProvider.overrideWith(() => CurrentGameNotifier()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: LoadGameListDialog(fromPause: fromPause)),
      ),
    );
  }

  testWidgets('empty list shows empty state', (tester) async {
    await tester.pumpWidget(host(fromPause: false));
    await tester.pumpAndSettle();

    expect(find.byKey(LoadGameListDialog.emptyStateKey), findsOneWidget);
    expect(find.text('No saved games.'), findsOneWidget);
  });

  testWidgets('positive: selecting row loads and navigates from menu', (
    tester,
  ) async {
    final events = <AppEvent>[];
    final sub = bus.stream.listen(events.add);
    addTearDown(sub.cancel);

    await tester.pumpWidget(
      host(
        fromPause: false,
        entries: const [
          LoadableSaveEntry(
            storageId: 'manual_a',
            label: 'Spain Save',
            kind: LoadableSaveKind.manual,
            turnNumber: 9,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(LoadGameListDialog.rowKey('manual_a')));
    await tester.pumpAndSettle();

    expect(
      events.whereType<NavigateToRouteEvent>().single.route,
      Routes.game,
    );
    expect(find.byType(LoadGameListDialog), findsNothing);
  });

  testWidgets('fromPause: discard cancel leaves dialog open without navigate', (
    tester,
  ) async {
    final events = <AppEvent>[];
    final sub = bus.stream.listen(events.add);
    addTearDown(sub.cancel);

    await tester.pumpWidget(
      host(
        fromPause: true,
        entries: const [
          LoadableSaveEntry(
            storageId: 'manual_a',
            label: 'Spain Save',
            kind: LoadableSaveKind.manual,
            turnNumber: 9,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(LoadGameListDialog.rowKey('manual_a')));
    await tester.pumpAndSettle();
    expect(find.byKey(LoadGameListDialog.discardConfirmKey), findsOneWidget);

    await tester.tap(find.byKey(LoadGameListDialog.discardCancelButtonKey));
    await tester.pumpAndSettle();

    expect(events.whereType<NavigateToRouteEvent>(), isEmpty);
    expect(events.whereType<ClosePanelEvent>(), isEmpty);
    expect(find.byType(LoadGameListDialog), findsOneWidget);
  });
}
