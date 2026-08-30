import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/features/shell/save_load/load_game_list_dialog.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'load_game_list_dialog_test_support.dart';

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;
  late LoadDialogGameService service;
  late AppEventBus bus;

  Widget host({
    required bool fromPause,
    List<LoadableSaveEntry> entries = const [],
    String? previewPendingDeleteId,
  }) {
    return loadGameListDialogHost(
      gamesBox: gamesBox,
      service: service,
      bus: bus,
      fromPause: fromPause,
      entries: entries,
      previewPendingDeleteId: previewPendingDeleteId,
    );
  }

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_load_list_dialog');
    gamesBox = await Hive.openBox<dynamic>('${HiveBoxNames.games}_load_list');
  });

  setUp(() async {
    await gamesBox.clear();
    AppEventBus.reset();
    bus = AppEventBus.create();
    service = LoadDialogGameService(gamesBox, GameSaveAdapter());
  });

  tearDown(() {
    bus.dispose();
  });

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

    expect(events.whereType<NavigateToRouteEvent>().single.route, Routes.game);
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
          loadDialogManualEntry(1),
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
        entries: [for (var i = 0; i < 10; i++) loadDialogManualEntry(i)],
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
          for (var i = 0; i < 11; i++) loadDialogManualEntry(i),
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
      host(fromPause: false, entries: [loadDialogManualEntry(1)]),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(LoadGameListDialog.deleteButtonKey('manual_1')),
    );
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
          loadDialogManualEntry(1),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(LoadGameListDialog.deleteButtonKey('manual_1')),
    );
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
          loadDialogManualEntry(1),
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
