import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/features/shell/save_load/save_game_name_dialog.dart';
import 'package:colonizethis_app/features/shell/save_load/default_save_display_name.dart';
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

class _SaveDialogGameService extends GameService {
  _SaveDialogGameService(super.box, super.adapter);

  List<String> existingIds = const [];
  bool allowNewManual = true;
  int saveCalls = 0;
  String? lastSaveId;
  String? lastDisplayName;

  @override
  List<String> listGameIds() => existingIds;

  @override
  bool canCreateNewManualSave() => allowNewManual;

  @override
  void saveGameSession({
    required Game sessionGame,
    required String saveGameId,
    Orders draftOrders = const Orders(),
    Map<String, int> productionDesiredOutputByRecipe = const <String, int>{},
    String? displayName,
    bool mirrorAutoSave = true,
  }) {
    saveCalls += 1;
    lastSaveId = saveGameId;
    lastDisplayName = displayName;
  }
}

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;
  late _SaveDialogGameService service;
  late AppEventBus bus;

  final game = Game(
    id: 'session',
    worldState: const WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 5),
      oldWorld: RegionData(),
      newWorld: RegionData(),
    ),
    players: const [
      Player(
        id: 'england',
        displayName: 'England',
        isHuman: true,
        leaderKey: 'england_leader',
      ),
    ],
  );

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_save_name_dialog');
    gamesBox = await Hive.openBox<dynamic>('${HiveBoxNames.games}_save_name');
  });

  setUp(() async {
    await gamesBox.clear();
    AppEventBus.reset();
    bus = AppEventBus.create();
    service = _SaveDialogGameService(gamesBox, GameSaveAdapter());
  });

  tearDown(() {
    bus.dispose();
  });

  Widget host() {
    // Editorial shell via buildAppShell (Refs #4035 — no inline MaterialApp).
    return buildAppShell(
      overrides: [
        gamesBoxProvider.overrideWithValue(gamesBox),
        gameServiceProvider.overrideWith((ref) => service),
        appEventBusProvider.overrideWith((ref) => bus),
        currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
      ],
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      child: const Scaffold(body: SaveGameNameDialog()),
    );
  }

  test('defaultSaveDisplayName uses nation leader turn', () {
    final name = defaultSaveDisplayName(game);
    expect(name, contains('England'));
    expect(name, contains('5'));
    expect(name.split(' - '), hasLength(3));
  });

  testWidgets('positive: Save persists sanitized id and pops', (tester) async {
    final snacks = <ShowSnackBarEvent>[];
    final sub = bus.on<ShowSnackBarEvent>().listen(snacks.add);
    addTearDown(sub.cancel);

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(SaveGameNameDialog.nameFieldKey),
      'My Campaign',
    );
    await tester.tap(find.byKey(SaveGameNameDialog.saveButtonKey));
    await tester.pumpAndSettle();

    expect(service.saveCalls, 1);
    expect(service.lastSaveId, 'My_Campaign');
    expect(service.lastDisplayName, 'My Campaign');
    expect(snacks.single.message, 'Game saved');
    expect(find.byType(SaveGameNameDialog), findsNothing);
  });

  testWidgets('negative: empty sanitize shows error and stays open', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(SaveGameNameDialog.nameFieldKey), '   ');
    await tester.tap(find.byKey(SaveGameNameDialog.saveButtonKey));
    await tester.pumpAndSettle();

    expect(find.byKey(SaveGameNameDialog.errorTextKey), findsOneWidget);
    expect(service.saveCalls, 0);
    expect(find.byType(SaveGameNameDialog), findsOneWidget);
  });

  testWidgets('negative: overwrite cancel does not save', (tester) async {
    service.existingIds = ['My_Campaign'];
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(SaveGameNameDialog.nameFieldKey),
      'My Campaign',
    );
    await tester.tap(find.byKey(SaveGameNameDialog.saveButtonKey));
    await tester.pumpAndSettle();

    expect(find.byKey(SaveGameNameDialog.overwriteConfirmKey), findsOneWidget);
    await tester.tap(find.byKey(SaveGameNameDialog.overwriteCancelButtonKey));
    await tester.pumpAndSettle();

    expect(service.saveCalls, 0);
    expect(find.byType(SaveGameNameDialog), findsOneWidget);
  });

  testWidgets('negative: at-cap new id shows error and does not save', (
    tester,
  ) async {
    service.allowNewManual = false;
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(SaveGameNameDialog.nameFieldKey),
      'Fresh Slot',
    );
    await tester.tap(find.byKey(SaveGameNameDialog.saveButtonKey));
    await tester.pumpAndSettle();

    expect(find.byKey(SaveGameNameDialog.errorTextKey), findsOneWidget);
    expect(find.textContaining('20 saves'), findsOneWidget);
    expect(service.saveCalls, 0);
    expect(find.byType(SaveGameNameDialog), findsOneWidget);
  });
}
