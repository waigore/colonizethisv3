// UNIT10001 Counter-espionage Assign shortcut (Refs #4528).
// SPEC: SPEC/ui/civilian-units-panel.md

import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kUnitTypeExplorer, kUnitTypeSpy, kWorkTargetCounterSpy;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'civilian_units_panel_test_support.dart';

const _human = 'h1';
const _homeTile = 'oldWorld|p1|0|0';

void main() {
  suppressLogsForTests();
  final l10n = AppLocalizationsEn();

  testWidgets('spyOnly filters the roster to Spies', (tester) async {
    final game = buildCivilianOwUnitsGame(
      id: 'g_ce_only_filter',
      extraProvinces: [
        const Province(
          id: 'oldWorld|p2',
          regionId: 'oldWorld',
          displayName: 'Rival Land',
        ),
      ],
      units: [
        civilianIdleUnit(
          id: 'e1',
          type: kUnitTypeExplorer,
          ownerId: _human,
          provinceId: 'oldWorld|p1',
          tileKey: _homeTile,
        ),
        civilianIdleUnit(
          id: 'spy1',
          type: kUnitTypeSpy,
          ownerId: _human,
          provinceId: 'oldWorld|p1',
          tileKey: _homeTile,
        ),
      ],
    );
    await tester.pumpWidget(
      buildCivilianPanel(
        game: game,
        humanPlayerId: _human,
        spyOnly: true,
        counterSpyShortcutTargetTileKey: _homeTile,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(kUnitTypeSpy), findsWidgets);
    expect(find.text(kUnitTypeExplorer), findsNothing);
  });

  testWidgets('Assign shortcut commits counter_spy without map pick', (
    tester,
  ) async {
    final bus = AppEventBus.create();
    final selections = <StartCivilianWorkTargetSelectionEvent>[];
    final upserts = <UpsertPendingCivilianWorkOrderRequestedEvent>[];
    bus.on<StartCivilianWorkTargetSelectionEvent>().listen(selections.add);
    bus.on<UpsertPendingCivilianWorkOrderRequestedEvent>().listen(upserts.add);
    final game = buildCivilianSpyFixtureGame(id: 'g_ce_shortcut_commit');
    await tester.pumpWidget(
      buildCivilianPanel(
        game: game,
        humanPlayerId: _human,
        bus: bus,
        spyOnly: true,
        counterSpyShortcutTargetTileKey: _homeTile,
        availableWorkTargets: {
          'spy1': [kWorkTargetCounterSpy],
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assign'));
    await tester.pumpAndSettle();
    expect(selections, isEmpty);
    expect(upserts, hasLength(1));
    expect(upserts.single.workOrder.unitId, 'spy1');
    expect(upserts.single.workOrder.target, kWorkTargetCounterSpy);
    expect(upserts.single.workOrder.targetTileKey, _homeTile);
    expect(find.textContaining('Assign work'), findsNothing);
  });

  testWidgets('invalid shortcut Assign is a silent no-op', (tester) async {
    final bus = AppEventBus.create();
    final selections = <StartCivilianWorkTargetSelectionEvent>[];
    final upserts = <UpsertPendingCivilianWorkOrderRequestedEvent>[];
    bus.on<StartCivilianWorkTargetSelectionEvent>().listen(selections.add);
    bus.on<UpsertPendingCivilianWorkOrderRequestedEvent>().listen(upserts.add);
    final game = buildCivilianSpyFixtureGame(id: 'g_ce_shortcut_noop');
    await tester.pumpWidget(
      buildCivilianPanel(
        game: game,
        humanPlayerId: _human,
        bus: bus,
        spyOnly: true,
        counterSpyShortcutTargetTileKey: _homeTile,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assign'));
    await tester.pumpAndSettle();
    expect(selections, isEmpty);
    expect(upserts, isEmpty);
  });

  testWidgets('Assign menu uses Counter-espionage and whole-realm gist', (
    tester,
  ) async {
    final game = buildCivilianSpyFixtureGame(id: 'g_ce_menu_label');
    await tester.pumpWidget(
      buildCivilianPanel(
        game: game,
        humanPlayerId: _human,
        availableWorkTargets: {
          'spy1': [kWorkTargetCounterSpy],
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assign'));
    await tester.pumpAndSettle();
    expect(find.text('Counter spy'), findsNothing);
    expect(
      find.text(l10n.provinceOverlay_counterEspionageAction),
      findsWidgets,
    );
    expect(
      find.text(l10n.provinceOverlay_counterEspionageGist),
      findsOneWidget,
    );
  });
}
