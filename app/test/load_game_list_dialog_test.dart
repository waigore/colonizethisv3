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
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'support/app_shell_harness.dart';

class _LoadDialogGameService extends GameService {
  _LoadDialogGameService(super.box, super.adapter);

  List<LoadableSaveEntry> entries = const [];
  GameSaveSession? sessionToLoad;
  final List<String> deletedIds = <String>[];

  @override
  List<LoadableSaveEntry> listLoadableSaves() => entries;

  @override
  void deleteSave(String storageId) {
    deletedIds.add(storageId);
    entries = entries.where((e) => e.storageId != storageId).toList();
  }

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

LoadableSaveEntry _manual(int i, {DateTime? at}) {
  return LoadableSaveEntry(
    storageId: 'manual_$i',
    label: 'Save $i',
    kind: LoadableSaveKind.manual,
    turnNumber: i,
    calendarYear: 1500 + i,
    humanNation: 'England',
    lastSavedAt: at ?? DateTime.utc(2026, 7, 12, 12, i),
  );
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

  Widget host({
    required bool fromPause,
    List<LoadableSaveEntry> entries = const [],
    String? previewPendingDeleteId,
  }) {
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
    // Editorial shell via buildAppShell (Refs #4035 — no inline MaterialApp).
    return buildAppShell(
      overrides: [
        gamesBoxProvider.overrideWithValue(gamesBox),
        gameServiceProvider.overrideWith((ref) => service),
        appEventBusProvider.overrideWith((ref) => bus),
        currentGameProvider.overrideWith(() => CurrentGameNotifier()),
      ],
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      child: Scaffold(
        body: LoadGameListDialog(
          fromPause: fromPause,
          previewPendingDeleteId: previewPendingDeleteId,
        ),
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

  testWidgets('positive: three-line row shows meta and last-saved', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        fromPause: false,
        entries: [
          LoadableSaveEntry(
            storageId: 'manual_a',
            label: 'Spain Save',
            kind: LoadableSaveKind.manual,
            turnNumber: 12,
            calendarYear: 1522,
            humanNation: 'Spain',
            lastSavedAt: DateTime.utc(2026, 7, 12, 8, 30),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Spain Save'), findsOneWidget);
    expect(
      find.byKey(LoadGameListDialog.rowMetaKey('manual_a')),
      findsOneWidget,
    );
    expect(find.textContaining('Turn 12'), findsOneWidget);
    expect(find.textContaining('1522'), findsOneWidget);
    expect(find.textContaining('Spain'), findsWidgets);
    expect(
      find.byKey(LoadGameListDialog.rowSavedAtKey('manual_a')),
      findsOneWidget,
    );
  });

  testWidgets('auto-save is delineated and pinned above manuals', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        fromPause: false,
        entries: [
          const LoadableSaveEntry(
            storageId: kAutoSaveSlotId,
            label: kAutoSaveListLabel,
            kind: LoadableSaveKind.autoSave,
            turnNumber: 3,
          ),
          _manual(1),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(LoadGameListDialog.autoSaveSectionKey), findsOneWidget);
    expect(find.text('Auto-save'), findsWidgets);
    expect(find.byKey(LoadGameListDialog.pagerKey), findsNothing);
  });

  testWidgets('≤10 manuals hides pager; 11 manuals pages with Next/Previous', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        fromPause: false,
        entries: [for (var i = 0; i < 10; i++) _manual(i)],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(LoadGameListDialog.pagerKey), findsNothing);

    await tester.pumpWidget(
      host(
        fromPause: false,
        entries: [
          const LoadableSaveEntry(
            storageId: kAutoSaveSlotId,
            label: kAutoSaveListLabel,
            kind: LoadableSaveKind.autoSave,
            turnNumber: 99,
          ),
          for (var i = 0; i < 11; i++) _manual(i),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(LoadGameListDialog.pagerKey), findsOneWidget);
    expect(find.text('Page 1 of 2'), findsOneWidget);
    expect(find.byKey(LoadGameListDialog.rowKey('manual_0')), findsOneWidget);
    expect(find.byKey(LoadGameListDialog.rowKey('manual_10')), findsNothing);
    expect(find.byKey(LoadGameListDialog.autoSaveSectionKey), findsOneWidget);

    await tester.tap(find.byKey(LoadGameListDialog.nextButtonKey));
    await tester.pumpAndSettle();

    expect(find.text('Page 2 of 2'), findsOneWidget);
    expect(find.byKey(LoadGameListDialog.rowKey('manual_10')), findsOneWidget);
    expect(find.byKey(LoadGameListDialog.autoSaveSectionKey), findsOneWidget);

    await tester.tap(find.byKey(LoadGameListDialog.previousButtonKey));
    await tester.pumpAndSettle();
    expect(find.text('Page 1 of 2'), findsOneWidget);
  });

  testWidgets('negative: delete cancel leaves storage unchanged', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        fromPause: false,
        entries: [_manual(1)],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(LoadGameListDialog.deleteButtonKey('manual_1')));
    await tester.pumpAndSettle();
    expect(find.byKey(LoadGameListDialog.deleteConfirmKey), findsOneWidget);

    await tester.tap(find.byKey(LoadGameListDialog.deleteCancelButtonKey));
    await tester.pumpAndSettle();

    expect(service.deletedIds, isEmpty);
    expect(find.byKey(LoadGameListDialog.rowKey('manual_1')), findsOneWidget);
  });

  testWidgets('positive: delete confirm removes save and stays open', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        fromPause: false,
        entries: [
          const LoadableSaveEntry(
            storageId: kAutoSaveSlotId,
            label: kAutoSaveListLabel,
            kind: LoadableSaveKind.autoSave,
            turnNumber: 3,
          ),
          _manual(1),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(LoadGameListDialog.deleteButtonKey('manual_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(LoadGameListDialog.deleteConfirmButtonKey));
    await tester.pumpAndSettle();

    expect(service.deletedIds, ['manual_1']);
    expect(find.byType(LoadGameListDialog), findsOneWidget);
    expect(find.byKey(LoadGameListDialog.rowKey('manual_1')), findsNothing);
    expect(find.byKey(LoadGameListDialog.autoSaveSectionKey), findsOneWidget);
  });

  testWidgets('positive: confirm delete clears auto-save slot', (tester) async {
    await tester.pumpWidget(
      host(
        fromPause: false,
        entries: [
          const LoadableSaveEntry(
            storageId: kAutoSaveSlotId,
            label: kAutoSaveListLabel,
            kind: LoadableSaveKind.autoSave,
            turnNumber: 3,
          ),
          _manual(1),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(LoadGameListDialog.deleteButtonKey(kAutoSaveSlotId)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(LoadGameListDialog.deleteConfirmButtonKey));
    await tester.pumpAndSettle();

    expect(service.deletedIds, [kAutoSaveSlotId]);
    expect(find.byKey(LoadGameListDialog.autoSaveSectionKey), findsNothing);
    expect(find.byKey(LoadGameListDialog.rowKey('manual_1')), findsOneWidget);
  });
}
