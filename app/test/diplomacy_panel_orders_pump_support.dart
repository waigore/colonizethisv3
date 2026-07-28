// Shared pump/tap helpers for diplomacy orders widget tests (Refs #4021, #4181).

import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'diplomacy_panel_test_support.dart';
import 'panel_test_fixtures.dart';

const diplomacyOrdersHumanId = kPanelTestHumanPlayerId;
const diplomacyOrdersGp2 = 'gp2';
const diplomacyOrdersMinorId = 'm1';

Future<void> pumpDiplomacyOrdersPanel(
  WidgetTester tester, {
  required Game game,
  String humanId = diplomacyOrdersHumanId,
  AppEventBus? bus,
  Orders currentOrders = const Orders(),
  bool tall = false,
  bool minorsTab = false,
  bool settle = false,
}) async {
  if (tall) {
    await bindDiplomacyTallTestSurface(tester);
  }
  await tester.pumpWidget(
    buildDiplomacyPanelShell(
      game: game,
      humanPlayerId: humanId,
      topology: const MapTopology(),
      currentOrders: currentOrders,
      bus: bus ?? AppEventBus.create(),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  if (minorsTab) {
    await tester.tap(find.text('Minors only'));
    await tester.pump();
  }
}

Finder diplomacyMinorRow() =>
    find.byKey(ValueKey('$kDiplomacyRowBodyKeyPrefix$diplomacyOrdersMinorId'));

Future<void> tapVisibleDiplomacy(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump();
}

Future<T> awaitDiplomacyBusEvent<T extends AppEvent>(AppEventBus bus) {
  return bus.on<T>().first.timeout(const Duration(seconds: 2));
}

void autoConfirmDiplomacyDialogs(AppEventBus bus) {
  final sub = bus.on<ConfirmDialogEvent>().listen((event) {
    event.result(true);
  });
  addTearDown(sub.cancel);
}

Orders diplomacyPendingOrders(DiplomaticOrder order) {
  return Orders(
    diplomaticOrdersByPlayerId: {
      diplomacyOrdersHumanId: [order],
    },
  );
}

Future<ConfirmDialogEvent> awaitConfirmOnDiplomacyActionTap(
  WidgetTester tester, {
  required Game game,
  required Finder actionFinder,
  AppEventBus? bus,
  bool minorsTab = false,
  bool tall = false,
}) async {
  final eventBus = bus ?? AppEventBus.create();
  final confirmFuture = eventBus
      .on<ConfirmDialogEvent>()
      .first
      .timeout(const Duration(seconds: 2));
  await pumpDiplomacyOrdersPanel(
    tester,
    game: game,
    bus: eventBus,
    minorsTab: minorsTab,
    tall: tall,
  );
  await tapVisibleDiplomacy(tester, actionFinder);
  return await confirmFuture;
}
