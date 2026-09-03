// Load-game list dialog delete confirm/cancel ACs (Refs #4720 Slice G).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/shell/save_load/load_game_list_dialog.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'load_game_list_dialog_test_support.dart';
import 'app_test_hive_harness.dart';

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
    gamesBox = await openAppTestHiveBox(
      suiteId: 'load_list_dialog_delete',
      boxName: '${HiveBoxNames.games}_load_list_delete',
    );
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
