// Load-game list dialog test doubles (Refs #4582).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/features/shell/save_load/load_game_list_dialog.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';

class LoadDialogGameService extends GameService {
  LoadDialogGameService(super.box, super.adapter);

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

LoadableSaveEntry loadDialogManualEntry(int i, {DateTime? at}) {
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

final Game loadDialogSampleGame = Game(
  id: 'manual_a',
  worldState: WorldState(
    turnState: TurnState(phase: TurnPhase.orders, turnNumber: 9),
    oldWorld: RegionData(),
    newWorld: RegionData(),
  ),
  players: [Player(id: 'gp1', displayName: 'Spain', isHuman: true)],
);

Widget loadGameListDialogHost({
  required Box<dynamic> gamesBox,
  required LoadDialogGameService service,
  required AppEventBus bus,
  required bool fromPause,
  List<LoadableSaveEntry> entries = const [],
  String? previewPendingDeleteId,
}) {
  service.entries = entries;
  service.sessionToLoad = GameSaveSession(
    game: loadDialogSampleGame,
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
