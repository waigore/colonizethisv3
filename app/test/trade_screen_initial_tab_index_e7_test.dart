// Widget tests for the Deal Book initial-tab override (Refs #2993 E7).
// SPEC/ui/trade-screen.md § Deal Book tab — initial tab override +
// Widgetbook stories.
//
// Exercises the durable contract for `TradeScreen.initialTabIndex` and
// the underlying `CtTabStrip.initialTabIndex` shared primitive added
// alongside the Deal Book Widgetbook stories:
//
//  * `TradeScreen.initialTabIndex: 1` mounts with the Deal Book tab
//    body foregrounded on the first frame, without simulating any
//    label tap;
//  * the production-route default (`initialTabIndex` omitted) keeps
//    the Market tab body foregrounded so the existing E4 contract is
//    preserved;
//  * `CtTabStrip.initialTabIndex` rejects out-of-bounds values via the
//    constructor `assert` so programmer errors fail loudly in debug;
//  * the Widgetbook `tradeScreenDirectories` register the documented
//    Deal Book stories in the SPEC-pinned order so reviewers can
//    audit the live ledger chrome.

import 'package:colonizethis_app/features/game/screens/trade_screen.dart';
import 'package:colonizethis_app/widgets/ct_tab_strip.dart';
import 'package:colonizethis_app/widgetbook/catalog.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart' show WidgetbookFolder, WidgetbookUseCase;

import 'support/app_shell_harness.dart';

Game _buildGameForTradeScreen() {
  return Game(
    id: 'test_trade_screen_e7',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    turnTimeMapping: TurnTimeMapping.gdd01,
    players: [
      // ignore: avoid_hardcoded_strings_in_widgets
      Player(id: 'gp_h', displayName: 'England', isHuman: true, treasury: 500),
    ],
    diplomacyRelations: const [],
    diplomaticHistoryEvents: const [],
    dossierEvidenceEntries: const [],
    worldMarketState: const WorldMarketState(),
  );
}

Future<void> _pumpTradeScreen(
  WidgetTester tester, {
  required Game game,
  int? initialTabIndex,
}) async {
  final Player player = game.players.firstWhere((p) => p.isHuman);
  final TradeScreen screen = initialTabIndex == null
      ? TradeScreen(game: game, player: player)
      : TradeScreen(
          game: game,
          player: player,
          initialTabIndex: initialTabIndex,
        );
  await pumpAppShell(tester, child: screen);
}

void main() {
  suppressLogsForTests();

  group('TradeScreen initialTabIndex (Refs #2993 E7)', () {
    testWidgets(
      'initialTabIndex: 1 foregrounds the Deal Book tab body on first '
      'frame without simulating a label tap',
      (tester) async {
        await _pumpTradeScreen(
          tester,
          game: _buildGameForTradeScreen(),
          initialTabIndex: 1,
        );

        // Foregrounded (visible) on first frame: Deal Book body.
        expect(
          find.byKey(TradeScreen.dealBookTabBodyKey),
          findsOneWidget,
        );
        expect(
          find.byKey(TradeScreen.dealBookContentKey),
          findsOneWidget,
        );

        // Off-stage (still in the IndexedStack): Market body. Found
        // only when `skipOffstage: false` is explicitly passed.
        expect(
          find.byKey(TradeScreen.marketTabBodyKey),
          findsNothing,
        );
        expect(
          find.byKey(TradeScreen.marketTabBodyKey, skipOffstage: false),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'default initialTabIndex (omitted) preserves the Market tab '
      'foregrounded contract from E4',
      (tester) async {
        await _pumpTradeScreen(
          tester,
          game: _buildGameForTradeScreen(),
        );

        expect(
          find.byKey(TradeScreen.marketTabBodyKey),
          findsOneWidget,
        );
        expect(
          find.byKey(TradeScreen.dealBookTabBodyKey),
          findsNothing,
        );
        expect(
          find.byKey(TradeScreen.dealBookTabBodyKey, skipOffstage: false),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'initialTabIndex: 0 explicitly mirrors the omitted-default '
      'contract',
      (tester) async {
        await _pumpTradeScreen(
          tester,
          game: _buildGameForTradeScreen(),
          initialTabIndex: 0,
        );

        expect(
          find.byKey(TradeScreen.marketTabBodyKey),
          findsOneWidget,
        );
        expect(
          find.byKey(TradeScreen.dealBookTabBodyKey),
          findsNothing,
        );
      },
    );
  });

  group('CtTabStrip initialTabIndex (Refs #2993 E7)', () {
    testWidgets(
      'positive initialTabIndex foregrounds the matching tab body on '
      'first frame',
      (tester) async {
        await pumpAppShell(
          tester,
          child: Scaffold(
            body: CtTabStrip(
              initialTabIndex: 1,
              tabLabels: const <String>['First', 'Second', 'Third'],
              tabViews: const <Widget>[
                Text(
                  'first-body',
                  key: ValueKey<String>('tab-body-first'),
                ),
                Text(
                  'second-body',
                  key: ValueKey<String>('tab-body-second'),
                ),
                Text(
                  'third-body',
                  key: ValueKey<String>('tab-body-third'),
                ),
              ],
            ),
          ),
        );

        expect(
          find.byKey(const ValueKey<String>('tab-body-second')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('tab-body-first')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey<String>('tab-body-third')),
          findsNothing,
        );
      },
    );

    test(
      'out-of-bounds initialTabIndex throws an assertion error '
      '(programmer-error contract)',
      () {
        expect(
          () => CtTabStrip(
            initialTabIndex: 5,
            tabLabels: const <String>['A', 'B'],
            tabViews: const <Widget>[Text('a'), Text('b')],
          ),
          throwsA(isA<AssertionError>()),
        );
        expect(
          () => CtTabStrip(
            initialTabIndex: -1,
            tabLabels: const <String>['A', 'B'],
            tabViews: const <Widget>[Text('a'), Text('b')],
          ),
          throwsA(isA<AssertionError>()),
        );
      },
    );
  });

  group('Widgetbook tradeScreenDirectories (Refs #2993 E7)', () {
    test(
      'registers exactly one Trade Screen folder containing the SPEC-'
      'pinned use cases in documented order',
      () {
        final directories = tradeScreenDirectories;
        expect(directories, hasLength(1));
        final folder = directories.single;
        expect(folder, isA<WidgetbookFolder>());
        final tradeFolder = folder as WidgetbookFolder;
        expect(tradeFolder.name, 'Trade Screen');

        final children = tradeFolder.children ?? const [];
        final useCaseNames = <String>[
          for (final node in children)
            if (node is WidgetbookUseCase) node.name,
        ];
        expect(
          useCaseNames,
          <String>[
            'Scaffold (Market tab)',
            'Scaffold (mobile)',
            'Market tab — staged bid + offer (Refs #2993 E5b)',
            'Market tab — cargo saturated (Refs #2993 E5c)',
            'Market tab — sectioned grouping (Refs #3093)',
            'Market tab — sellable clamp (Refs #3093)',
            'Market tab — treasury bid cap (Refs #3093)',
            'Deal Book tab — empty (Refs #2993 E7)',
            'Deal Book tab — mixed fills + carry-forwards (Refs #2993 E7)',
            'Deal Book tab — mobile (stacked) (Refs #2993 E7)',
          ],
        );
      },
    );
  });
}
