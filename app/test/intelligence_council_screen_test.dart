// GAME30003 Intelligence Council. SPEC/ui/intelligence-council.md.

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

  testWidgets(
    'Given world war and capture When council renders Then world lines show names',
    (WidgetTester tester) async {
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
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('World briefing'), findsOneWidget);
      expect(find.text('France and Spain are now at war.'), findsOneWidget);
      expect(
        find.text('Paris: ownership changed from Spain to France.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Given France spy block When council renders Then prefixed spy copy',
    (WidgetTester tester) async {
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
                          kind: IntelligenceSpyKind.diplomatic,
                          diplomaticType: DiplomaticEventType.declareWar,
                          fromFactionId: 'france',
                          toFactionId: 'gp3',
                        ),
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
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Our spy in France reports:'),
        findsNWidgets(2),
      );
      expect(find.textContaining('Crop Rotation'), findsOneWidget);
      expect(find.textContaining('declared war'), findsOneWidget);
      expect(find.textContaining('hiddenAgenda'), findsNothing);
    },
  );

  testWidgets('Given empty digest When council renders Then empty copies', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        IntelligenceCouncilBody(
          game: gameWith(
            const LastTurnIntelligenceDigest(resolvedTurnNumber: 2),
          ),
          humanPlayerId: 'gp1',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No major world events last turn.'), findsOneWidget);
    expect(
      find.text(
        'No spy reports. Station a Spy in a foreign province to hear that court\'s news.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'Given France-only facts without spy When council renders Then France secrets absent',
    (WidgetTester tester) async {
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
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Crop Rotation'), findsNothing);
      expect(find.textContaining('Our spy in France'), findsNothing);
    },
  );
}
