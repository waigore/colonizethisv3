// Shortcut-commit helpers for CivilianUnitsPanel part1 (Refs #4352).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'civilian_units_panel_test_support.dart';

const civilianPanelPart1HumanId = 'h1';
const civilianPanelPart1TileKey = 'oldWorld|p1|0|0';

Future<void> expectCivilianShortcutCommit(
  WidgetTester tester, {
  required String gameId,
  required String visibleType,
  required String hiddenType,
  required String unitId,
  required String workTarget,
  bool builderFirst = false,
  bool explorerOnly = false,
  bool builderOnly = false,
  bool engineerOnly = false,
  bool railBuilderOnly = false,
  bool merchantOnly = false,
  String? prospectShortcutTargetTileKey,
  String? exploreShortcutTargetTileKey,
  String? buildImprovementShortcutTargetTileKey,
  String? buildRoadShortcutTargetTileKey,
  String? buildRailShortcutTargetTileKey,
  String? purchaseLandShortcutTargetTileKey,
  bool expectCloseBeforeUpsert = true,
  Game Function(String id)? customGameBuilder,
}) async {
  const human = civilianPanelPart1HumanId;
  const tileKey = civilianPanelPart1TileKey;
  final bus = AppEventBus.create();
  final events = <Type>[];
  UpsertPendingCivilianWorkOrderRequestedEvent? upsertEvent;
  bus.stream.listen((e) => events.add(e.runtimeType));
  bus.on<UpsertPendingCivilianWorkOrderRequestedEvent>().listen(
    (event) => upsertEvent = event,
  );
  await tester.pumpWidget(
    buildCivilianPanel(
      game: customGameBuilder != null
          ? customGameBuilder(gameId)
          : buildCivilianExplorerBuilderShortcutGame(
              id: gameId,
              humanId: human,
              tileKey: tileKey,
              builderFirst: builderFirst,
            ),
      humanPlayerId: human,
      bus: bus,
      explorerOnly: explorerOnly,
      builderOnly: builderOnly,
      engineerOnly: engineerOnly,
      railBuilderOnly: railBuilderOnly,
      merchantOnly: merchantOnly,
      prospectShortcutTargetTileKey: prospectShortcutTargetTileKey,
      exploreShortcutTargetTileKey: exploreShortcutTargetTileKey,
      buildImprovementShortcutTargetTileKey:
          buildImprovementShortcutTargetTileKey,
      buildRoadShortcutTargetTileKey: buildRoadShortcutTargetTileKey,
      buildRailShortcutTargetTileKey: buildRailShortcutTargetTileKey,
      purchaseLandShortcutTargetTileKey: purchaseLandShortcutTargetTileKey,
      availableWorkTargets: {
        unitId: [workTarget],
      },
    ),
  );
  await tester.pumpAndSettle();

  expect(find.text(visibleType), findsOneWidget);
  expect(find.text(hiddenType), findsNothing);

  await tester.tap(find.text('Assign'));
  await tester.pump();
  await tester.pumpAndSettle();

  expect(find.textContaining('Assign work'), findsNothing);
  expect(upsertEvent, isNotNull);
  expect(upsertEvent!.playerId, human);
  expect(upsertEvent!.workOrder.unitId, unitId);
  expect(upsertEvent!.workOrder.target, workTarget);
  expect(upsertEvent!.workOrder.targetTileKey, tileKey);
  expect(events.contains(StartCivilianWorkTargetSelectionEvent), isFalse);
  if (expectCloseBeforeUpsert) {
    expect(
      events.indexOf(ClosePanelEvent),
      lessThan(events.indexOf(UpsertPendingCivilianWorkOrderRequestedEvent)),
    );
  }
}
