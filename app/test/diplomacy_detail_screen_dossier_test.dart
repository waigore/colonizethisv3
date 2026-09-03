// Diplomacy detail history/dossier matrix (GAME30002) (Refs #4720 Slice F).
// SPEC: SPEC/ui/diplomacy-detail-screen.md (history/dossier/relation chrome).

import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'widget_test_assets.dart';
import 'diplomacy_detail_screen_test_support.dart';

void main() {
  suppressLogsForTests();

  setUpAll(() async {
    await preloadNinePatchImage();
  });

  group('history / dossier matrix (GAME30002)', () {
    for (final c
        in <
          ({
            String name,
            Game Function() game,
            FactionKind kind,
            bool useRelation,
            List<DiplomacyDetailPin> pins,
          })
        >[
          (
            name: 'GP shows dossier header and empty evidence',
            game: diplomacyDetailMinimalGame,
            kind: FactionKind.greatPower,
            useRelation: true,
            pins: [
              (find.text('DIPLOMATIC HISTORY'), findsOneWidget),
              (find.text('DOSSIER'), findsOneWidget),
              (find.textContaining('No dossier evidence yet.'), findsOneWidget),
            ],
          ),
          (
            name: 'GP empty history when relation is null',
            game: diplomacyDetailMinimalGame,
            kind: FactionKind.greatPower,
            useRelation: false,
            pins: [
              (find.text('DIPLOMATIC HISTORY'), findsOneWidget),
              (find.text('DOSSIER'), findsOneWidget),
              (find.text('No dossier evidence yet.'), findsOneWidget),
              (
                find.text('No recorded events with this faction.'),
                findsOneWidget,
              ),
            ],
          ),
          (
            name: 'non-GP with relation shows Peace and hides Dossier',
            game: diplomacyDetailMinimalGame,
            kind: FactionKind.minor,
            useRelation: true,
            pins: [
              (find.text('DIPLOMATIC HISTORY'), findsOneWidget),
              (find.text('DOSSIER'), findsNothing),
              (
                find.text('No recorded events with this faction.'),
                findsOneWidget,
              ),
              (find.textContaining('Peace'), findsOneWidget),
            ],
          ),
          (
            name: 'GP empty-state dossier when no evidence exists',
            game: () => diplomacyDetailMinimalGame(
              eventType: DiplomaticEventType.declareWar,
            ),
            kind: FactionKind.greatPower,
            useRelation: true,
            pins: [
              (find.text('DIPLOMATIC HISTORY'), findsOneWidget),
              (find.text('DOSSIER'), findsOneWidget),
              (
                find.text('No recorded events with this faction.'),
                findsOneWidget,
              ),
              (find.text('No dossier evidence yet.'), findsOneWidget),
              (find.textContaining('Peace'), findsOneWidget),
            ],
          ),
          (
            name: 'GP non-empty history + dossier at war',
            game: () => diplomacyDetailMinimalGame(
              eventType: DiplomaticEventType.declareWar,
              includeHistory: true,
              includeDossier: true,
              atWar: true,
            ),
            kind: FactionKind.greatPower,
            useRelation: true,
            pins: [
              (find.text('DIPLOMATIC HISTORY'), findsOneWidget),
              (find.text('DOSSIER'), findsOneWidget),
              (find.textContaining('Turn 3:'), findsOneWidget),
              (find.textContaining('evidence-1'), findsOneWidget),
              (find.textContaining('declared war'), findsOneWidget),
              (find.textContaining('War'), findsOneWidget),
            ],
          ),
          (
            name: 'GP non-empty history with empty Dossier at war',
            game: () => diplomacyDetailMinimalGame(
              eventType: DiplomaticEventType.declareWar,
              includeHistory: true,
              atWar: true,
            ),
            kind: FactionKind.greatPower,
            useRelation: true,
            pins: [
              (find.text('DIPLOMATIC HISTORY'), findsOneWidget),
              (find.text('DOSSIER'), findsOneWidget),
              (find.textContaining('declared war'), findsOneWidget),
              (find.textContaining('War'), findsOneWidget),
              (find.text('No dossier evidence yet.'), findsOneWidget),
            ],
          ),
        ]) {
      testWidgets(c.name, (WidgetTester tester) async {
        final game = c.game();
        final relation = c.useRelation
            ? getRelation(game, diplomacyDetailHumanId, diplomacyDetailOtherId)
            : null;
        await pumpDiplomacyDetailOtherGp(
          tester,
          game: game,
          kind: c.kind,
          relation: relation,
        );
        for (final (finder, matcher) in c.pins) {
          expect(finder, matcher);
        }
      });
    }
  });
}
