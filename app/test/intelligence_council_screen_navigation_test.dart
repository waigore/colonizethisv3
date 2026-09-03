// GAME30003 Intelligence Council tap navigation ACs (Refs #4720 Slice G).
// SPEC/ui/intelligence-council.md.

import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/features/game/screens/diplomacy/intelligence_council_screen.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

void main() {
  suppressLogsForTests();

  Widget wrap(Widget child) {
    return buildAppShell(
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      child: Scaffold(body: child),
    );
  }

  Game gameWith(LastTurnIntelligenceDigest digest) {
    return Game(
      id: 'g',
      worldState: const WorldState(
        turnState: TurnState(phase: TurnPhase.orders, turnNumber: 3),
        oldWorld: RegionData(
          provinces: [
            Province(
              id: 'oldWorld|fr1',
              regionId: 'oldWorld',
              ownerId: 'france',
              displayName: 'Paris',
            ),
          ],
        ),
        newWorld: RegionData(),
      ),
      players: const [
        Player(id: 'gp1', displayName: 'England', isHuman: true, treasury: 0),
        Player(
          id: 'france',
          displayName: 'France',
          isHuman: false,
          treasury: 0,
        ),
        Player(id: 'gp3', displayName: 'Spain', isHuman: false, treasury: 0),
      ],
      lastTurnIntelligenceDigest: digest,
    );
  }

  testWidgets('Given world war line When tapped Then opens diplomacy detail', (
    WidgetTester tester,
  ) async {
    final bus = AppEventBus.create();
    addTearDown(bus.dispose);
    NavigateToRouteEvent? nav;
    bus.on<NavigateToRouteEvent>().listen((e) => nav = e);
    await tester.pumpWidget(
      wrap(
        IntelligenceCouncilBody(
          game: gameWith(
            const LastTurnIntelligenceDigest(
              resolvedTurnNumber: 2,
              worldLines: [
                IntelligenceWorldLine(
                  kind: IntelligenceWorldKind.war,
                  factionIdA: 'france',
                  factionIdB: 'gp3',
                ),
              ],
            ),
          ),
          humanPlayerId: 'gp1',
          bus: bus,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('France and Spain are now at war.'));
    await tester.pump();
    expect(nav?.route, Routes.diplomacyDetail);
    final args = nav?.arguments as Map<String, Object?>?;
    expect(args?['factionId'], 'gp3');
  });

  testWidgets(
    'Given capture world line When tapped Then map-focuses province',
    (WidgetTester tester) async {
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);
      final pops = <PopNavigationEvent>[];
      final opens = <OpenProvinceDetailPanelEvent>[];
      bus.on<PopNavigationEvent>().listen(pops.add);
      bus.on<OpenProvinceDetailPanelEvent>().listen(opens.add);
      await tester.pumpWidget(
        wrap(
          IntelligenceCouncilBody(
            game: gameWith(
              const LastTurnIntelligenceDigest(
                resolvedTurnNumber: 2,
                worldLines: [
                  IntelligenceWorldLine(
                    kind: IntelligenceWorldKind.provinceCaptured,
                    provinceId: 'oldWorld|fr1',
                    factionIdA: 'gp3',
                    factionIdB: 'france',
                  ),
                ],
              ),
            ),
            humanPlayerId: 'gp1',
            bus: bus,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.text('Paris: ownership changed from Spain to France.'),
      );
      await tester.pump();
      expect(pops, hasLength(1));
      expect(opens, hasLength(1));
      expect(opens.single.provinceId, 'oldWorld|fr1');
    },
  );

  testWidgets(
    'Given spy report line When tapped Then opens that court detail',
    (WidgetTester tester) async {
      final bus = AppEventBus.create();
      addTearDown(bus.dispose);
      NavigateToRouteEvent? nav;
      bus.on<NavigateToRouteEvent>().listen((e) => nav = e);
      await tester.pumpWidget(
        wrap(
          IntelligenceCouncilBody(
            game: gameWith(
              const LastTurnIntelligenceDigest(
                resolvedTurnNumber: 2,
                spyReportsByObserverId: {
                  'gp1': [
                    IntelligenceSpyCourtBlock(
                      courtFactionId: 'france',
                      lines: [
                        IntelligenceSpyLine(
                          kind: IntelligenceSpyKind.researchComplete,
                          techId: kTechIdCropRotation,
                          fromFactionId: 'france',
                        ),
                      ],
                    ),
                  ],
                },
              ),
            ),
            humanPlayerId: 'gp1',
            bus: bus,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Our spy in France reports:'));
      await tester.pump();
      expect(nav?.route, Routes.diplomacyDetail);
      final args = nav?.arguments as Map<String, Object?>?;
      expect(args?['factionId'], 'france');
    },
  );
}
