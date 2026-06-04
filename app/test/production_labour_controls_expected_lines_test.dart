// Pins the Labour Controls portion of the production-panel e2e expected-lines
// mirror (`productionLabourControlsExpectedTexts` in
// `app/lib/test_support/production_panel_e2e_expected_lines.dart`) against the
// real `ProductionLabourSection` widget + its `CtSectionLabel` header.
//
// The full `productionPanelWideExpectedTexts` mirror is exercised only by the
// integration-test scenario in `new_game_full_turn_e2e_test.dart`, which is a
// CI no-op per `SPEC/program/e2e-integration-tests.md` § CI. Before this pin
// the Labour Controls section was absent from the mirror, so its rendered
// `LABOUR CONTROLS` header drifted silently against the expected `Allocation`
// header until the slow E2E lane caught it. This widget-test layer asserts the
// mirror reproduces the section's pre-order `Text` data exactly, so drift
// surfaces at `flutter test` time.
//
// Refs GitHub #2336 (E2E expected-lines mirror alignment).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/production_labour_helpers.dart';
import 'package:colonizethis_app/features/game/widgets/production_labour_section.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_app/test_support/production_panel_e2e_expected_lines.dart';
import 'package:colonizethis_app/widgets/ct_section_label.dart';

import '../integration_test/e2e_helpers.dart' show collectTextPreorder;
import 'widget_test_pumps.dart';

const _playerId = 'gp_labour_mirror_test';
const _rootKey = ValueKey<String>('labour_controls_mirror_root');

Player _player({
  int peasants = 0,
  int apprentices = 0,
  int journeymen = 0,
  int masters = 0,
  int treasury = 0,
  Map<String, int> stockpile = const {},
  Map<String, bool>? techUnlocked,
}) {
  return Player(
    id: _playerId,
    displayName: 'Labour mirror GP',
    isHuman: true,
    workerPool: WorkerPool(
      peasants: peasants,
      apprentices: apprentices,
      journeymen: journeymen,
      masters: masters,
    ),
    stockpile: Stockpile(quantities: Map<String, int>.from(stockpile)),
    treasury: treasury,
    techUnlocked: techUnlocked,
  );
}

ProductionLabourCallbacks _noopCallbacks() => ProductionLabourCallbacks(
  onAppendRecruitOrder: (_) {},
  onPopLastRecruitOrder: (_) {},
  onDisband: (_) {},
);

/// Mirrors how `ProductionPanel._buildWorkerSection` appends the Labour
/// Controls block: a `CtSectionLabel` header immediately followed by the
/// `ProductionLabourSection`. The intervening `SizedBox`es render no `Text`
/// so they do not affect the pre-order text collection.
Widget _mount({
  required Player player,
  required Orders currentOrders,
  required bool canEdit,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: const [Locale('en')],
    home: Scaffold(
      body: SizedBox(
        width: 800,
        height: 600,
        child: KeyedSubtree(
          key: _rootKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CtSectionLabel(
                lookupAppLocalizations(
                  const Locale('en'),
                ).production_labourControlsSectionLabel,
              ),
              ProductionLabourSection(
                player: player,
                currentOrders: currentOrders,
                canEdit: canEdit,
                callbacks: _noopCallbacks(),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

List<String> _collected(WidgetTester tester) {
  final out = <String>[];
  collectTextPreorder(tester.element(find.byKey(_rootKey)), out);
  return out;
}

void main() {
  suppressLogsForTests();

  late AppLocalizations l10n;

  setUpAll(() {
    l10n = lookupAppLocalizations(const Locale('en'));
  });

  group('productionLabourControlsExpectedTexts', () {
    testWidgets(
      'mirror reproduces the rendered Labour Controls pre-order text '
      '(canEdit=true, mixed pool + queued + locked/unlocked tiers)',
      (tester) async {
        final player = _player(
          peasants: 2,
          apprentices: 1,
          journeymen: 1,
          masters: 1,
          treasury: 500,
          stockpile: {CommodityCatalog.paper.id: 50},
          // Unlock only the apprentice tier so the mirror's (unlocked)/(locked)
          // branch is exercised on both legs.
          techUnlocked: const {
            kTechIdApprenticeWorkers: true,
            kTechIdSugarRefining: true,
          },
        );
        final orders = Orders(
          recruitWorkerOrdersByPlayerId: {
            _playerId: const [
              RecruitWorkerOrder(targetTier: WorkerTier.peasant),
              RecruitWorkerOrder(targetTier: WorkerTier.peasant),
            ],
          },
        );

        await tester.pumpWidget(
          _mount(player: player, currentOrders: orders, canEdit: true),
        );
        await pumpSettleCapped(tester);

        final expected = productionLabourControlsExpectedTexts(
          player: player,
          currentOrders: orders,
          canEdit: true,
          l10n: l10n,
        );

        expect(
          _collected(tester),
          orderedEquals(expected),
          reason:
              'The expected-lines mirror must reproduce the rendered Labour '
              'Controls section pre-order Text data exactly; any drift here '
              'is the same drift the slow E2E lane would catch.',
        );

        // Absolute sanity pins on the values the mirror is built from.
        expect(
          expected.first,
          'LABOUR CONTROLS',
          reason: 'CtSectionLabel upper-cases the header text.',
        );
        expect(
          expected.where((t) => t == l10n.production_labourDisband).length,
          4,
          reason:
              'Disband label appears once per tier (3 trained buttons + the '
              'opacity-0 peasant reserved slot the collector still visits).',
        );
        expect(
          expected.contains(l10n.production_labourQueued(2)),
          isTrue,
          reason: 'Two queued peasant recruit orders render a Queued: 2 badge.',
        );
      },
    );

    testWidgets(
      'mirror reproduces the rendered section with no action labels when '
      'canEdit=false (negative: the canEdit=true mirror does not match)',
      (tester) async {
        final player = _player(peasants: 2, journeymen: 1);
        const orders = Orders();

        await tester.pumpWidget(
          _mount(player: player, currentOrders: orders, canEdit: false),
        );
        await pumpSettleCapped(tester);

        final collected = _collected(tester);

        expect(
          collected,
          orderedEquals(
            productionLabourControlsExpectedTexts(
              player: player,
              currentOrders: orders,
              canEdit: false,
              l10n: l10n,
            ),
          ),
          reason:
              'Read-only mode omits every action button, so no Disband label '
              'is emitted; the mirror must match that.',
        );
        expect(
          collected.contains(l10n.production_labourDisband),
          isFalse,
          reason: 'No Disband label renders when the panel is read-only.',
        );
        expect(
          collected,
          isNot(
            orderedEquals(
              productionLabourControlsExpectedTexts(
                player: player,
                currentOrders: orders,
                canEdit: true,
                l10n: l10n,
              ),
            ),
          ),
          reason:
              'The canEdit=true mirror adds Disband labels absent from the '
              'read-only render, so it must not match — guarding against the '
              'mirror ignoring the canEdit flag.',
        );
      },
    );
  });
}
