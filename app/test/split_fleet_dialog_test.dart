// Tests for SplitFleetDialog transfer/confirm. SPEC/ui/naval-units-fleet-management.md.
// Concern split under repo.app_test_file_size (Refs #4013, #4352, #4448).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/ct_transfer_list.dart';

import 'split_fleet_dialog_test_support.dart';

void main() {
  suppressLogsForTests();

  testWidgets('at-sea location subtitle uses sea-zone display name', (
    WidgetTester tester,
  ) async {
    await openSplitFleetDialog(
      tester,
      fleet: splitFleetAtSea(
        id: 'f_sea_label',
        shipTypeIds: const ['carrack'],
        seaZoneId: 's1',
      ),
      game: splitFleetMinimalGame(
        provinces: const [],
        seaZoneDisplayNameById: const {'oldWorld|s1': 'Adriatic Display'},
      ),
      isHomeFleet: false,
      bus: AppEventBus.create(),
    );

    expect(find.textContaining('Adriatic Display'), findsWidgets);
  });

  testWidgets('moving exactly one from three of a type leaves 2 and 1', (
    WidgetTester tester,
  ) async {
    await openSplitFleetDialog(
      tester,
      fleet: splitFleetAtSea(
        id: 'f1',
        shipTypeIds: const ['carrack', 'carrack', 'carrack', 'fluyte'],
      ),
      game: splitFleetMinimalGame(provinces: const []),
      isHomeFleet: false,
      bus: AppEventBus.create(),
    );

    expect(find.text('Carrack (3)'), findsOneWidget);
    await tester.tap(find.byKey(CtTransferListKeys.leftMoveOne('carrack')));
    await tester.pump();

    expect(find.text('Carrack (2)'), findsOneWidget);
    expect(find.text('Carrack (1)'), findsOneWidget);
    expect(find.text('Fluyte (1)'), findsOneWidget);
  });

  testWidgets(
    'bulk >> moves all remaining of a type after a single-carrier move (non-Home)',
    (WidgetTester tester) async {
      await openSplitFleetDialog(
        tester,
        fleet: splitFleetAtSea(
          id: 'f1b',
          shipTypeIds: const ['carrack', 'carrack', 'carrack', 'fluyte'],
        ),
        game: splitFleetMinimalGame(provinces: const []),
        isHomeFleet: false,
        bus: AppEventBus.create(),
      );

      await tester.tap(find.byKey(CtTransferListKeys.leftMoveOne('carrack')));
      await tester.pump();
      expect(find.text('Carrack (2)'), findsOneWidget);
      expect(find.text('Carrack (1)'), findsOneWidget);

      await tester.tap(find.byKey(CtTransferListKeys.leftMoveAll('carrack')));
      await tester.pump();
      expect(find.text('Carrack (3)'), findsOneWidget);
      expect(find.text('Fluyte (1)'), findsOneWidget);
    },
  );

  testWidgets(
    '<< moves all of a type from new back to original in one action',
    (WidgetTester tester) async {
      await openSplitFleetDialog(
        tester,
        fleet: splitFleetAtSea(
          id: 'f1c',
          shipTypeIds: const ['carrack', 'carrack', 'carrack', 'fluyte'],
        ),
        game: splitFleetMinimalGame(provinces: const []),
        isHomeFleet: false,
        bus: AppEventBus.create(),
      );

      await tester.tap(find.byKey(CtTransferListKeys.leftMoveAll('carrack')));
      await tester.pump();
      expect(find.text('Carrack (3)'), findsOneWidget);
      expect(find.text('Fluyte (1)'), findsOneWidget);

      await tester.tap(find.byKey(CtTransferListKeys.rightMoveAll('carrack')));
      await tester.pump();
      expect(find.text('Carrack (3)'), findsOneWidget);
      expect(find.text('Fluyte (1)'), findsOneWidget);
      expect(find.text('Carrack (2)'), findsNothing);
      expect(find.text('Carrack (1)'), findsNothing);
    },
  );

  testWidgets('confirm emits split request with only ships on new fleet side', (
    WidgetTester tester,
  ) async {
    NavalSplitFleetRequestedEvent? captured;
    final bus = AppEventBus.create();
    final sub = bus.on<NavalSplitFleetRequestedEvent>().listen((e) {
      captured = e;
    });
    addTearDown(sub.cancel);

    final fleet = splitFleetAtSea(
      id: 'f1d',
      shipTypeIds: const ['carrack', 'carrack', 'fluyte'],
    );

    await openSplitFleetDialog(
      tester,
      fleet: fleet,
      game: splitFleetMinimalGame(provinces: const []),
      isHomeFleet: false,
      bus: bus,
    );

    await tester.tap(find.byKey(CtTransferListKeys.leftMoveOne('carrack')));
    await tester.pump();
    await tester.tap(find.text('Confirm Split'));
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!.shipInstanceIdsToNewFleet, [fleet.ships.first.id]);
    expect(captured!.originalFleetId, fleet.id);
    expect(captured!.humanPlayerId, 'gp1');
  });

  testWidgets('per-row controls: one and all transfers with exact counts', (
    WidgetTester tester,
  ) async {
    await openSplitFleetDialog(
      tester,
      fleet: splitFleetAtSea(
        id: 'f2',
        shipTypeIds: const ['carrack', 'carrack', 'fluyte'],
      ),
      game: splitFleetMinimalGame(provinces: const []),
      isHomeFleet: false,
      bus: AppEventBus.create(),
    );

    expect(find.text('Carrack (2)'), findsOneWidget);
    await tester.tap(find.byKey(CtTransferListKeys.leftMoveOne('carrack')));
    await tester.pump();
    expect(find.text('Carrack (1)'), findsNWidgets(2));

    await tester.tap(find.byKey(CtTransferListKeys.leftMoveAll('carrack')));
    await tester.pump();
    expect(find.text('Carrack (2)'), findsOneWidget);
    expect(find.text('Carrack (1)'), findsNothing);

    await tester.tap(find.byKey(CtTransferListKeys.rightMoveOne('carrack')));
    await tester.pump();
    expect(find.text('Carrack (1)'), findsNWidgets(2));
  });

  testWidgets('arrow semantics: < is right-to-left and > is left-to-right', (
    WidgetTester tester,
  ) async {
    await openSplitFleetDialog(
      tester,
      fleet: splitFleetAtSea(id: 'f3', shipTypeIds: const ['fluyte', 'fluyte']),
      game: splitFleetMinimalGame(provinces: const []),
      isHomeFleet: false,
      bus: AppEventBus.create(),
    );

    await tester.tap(find.byKey(CtTransferListKeys.leftMoveOne('fluyte')));
    await tester.pump();
    expect(find.text('Fluyte (1)'), findsNWidgets(2));

    await tester.tap(find.byKey(CtTransferListKeys.rightMoveOne('fluyte')));
    await tester.pump();
    expect(find.text('Fluyte (2)'), findsOneWidget);
    expect(find.text('Fluyte (1)'), findsNothing);
  });

  testWidgets('home fleet can split to zero original ships', (
    WidgetTester tester,
  ) async {
    NavalSplitFleetRequestedEvent? captured;
    final bus = AppEventBus.create();
    final sub = bus.on<NavalSplitFleetRequestedEvent>().listen((e) {
      captured = e;
    });
    addTearDown(sub.cancel);

    final fleet = Fleet(
      id: 'home_fleet',
      ownerId: 'gp1',
      regionId: 'oldWorld',
      seaZoneId: 'oldWorld|s1',
      shipTypeIds: const ['carrack'],
    );

    await openSplitFleetDialog(
      tester,
      fleet: fleet,
      game: splitFleetMinimalGame(provinces: const []),
      isHomeFleet: true,
      bus: bus,
    );

    await tester.tap(find.byKey(CtTransferListKeys.leftMoveAll('carrack')));
    await tester.pump();

    expect(find.text('No ships'), findsOneWidget);
    expect(splitFleetButtonEnabled(tester, 'Confirm Split'), isTrue);

    final confirm = find.text('Confirm Split');
    await tester.ensureVisible(confirm);
    await tester.pump();
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(captured, isNotNull);
    expect(captured!.shipInstanceIdsToNewFleet, hasLength(1));
    expect(captured!.shipInstanceIdsToNewFleet.first, fleet.ships.single.id);
  });
}
