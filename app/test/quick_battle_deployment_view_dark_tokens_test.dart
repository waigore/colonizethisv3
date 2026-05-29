import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/combat/quick_battle_deployment_view.dart';

/// Pins SPEC/ui/quick-battle-deployment-view.md § Layout / wireframe and the
/// dark-theme `--muted` AC added under Refs #2869 S3 R14.
///
/// Each per-group `Text` row must resolve its foreground color to the canonical
/// `EditorialMonoclePalette.muted` token (the `--muted` token from
/// `SPEC/ui/pixel-art-ui-catalog.md` § Editorial-monocle palette) while still
/// inheriting the rest of `Theme.of(context).textTheme.bodySmall`.
void main() {
  suppressLogsForTests();

  Widget frame(Widget child) {
    return MaterialApp(
      theme: AppThemes.editorialMonocle,
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('QuickBattleDeploymentView dark editorial-monocle tokens', () {
    testWidgets('per-group rows resolve to --muted color', (tester) async {
      await tester.pumpWidget(
        frame(
          const QuickBattleDeploymentView(
            attackerDeployment: QuickBattleDeployment(
              groups: [
                QuickBattleGroup(
                  lane: QuickBattleLane.center,
                  line: QuickBattleLine.front,
                  unitIds: ['a1', 'a2', 'a3'],
                  cohesion: 3,
                ),
              ],
            ),
            defenderDeployment: QuickBattleDeployment(
              groups: [
                QuickBattleGroup(
                  lane: QuickBattleLane.center,
                  line: QuickBattleLine.front,
                  unitIds: ['d1', 'd2'],
                  cohesion: 2,
                ),
              ],
            ),
            attackerName: 'Castile',
            defenderName: 'England',
          ),
        ),
      );

      final Iterable<Text> rowTexts = tester
          .widgetList<Text>(find.byType(Text))
          .where((t) =>
              (t.data ?? '').contains('Center Front:') &&
              (t.data ?? '').contains('units'));
      expect(rowTexts, isNotEmpty,
          reason: 'Both attacker and defender groups should render rows.');
      for (final t in rowTexts) {
        expect(t.style, isNotNull,
            reason: 'Per-group row Text must explicitly carry a TextStyle.');
        expect(t.style!.color, EditorialMonoclePalette.muted,
            reason:
                'Per #2869 R14 + SPEC/ui/quick-battle-deployment-view.md, the '
                'per-group row text color must resolve to '
                'EditorialMonoclePalette.muted.');
      }
    });

    testWidgets('header titles do NOT inherit the --muted row color',
        (tester) async {
      await tester.pumpWidget(
        frame(
          const QuickBattleDeploymentView(
            attackerDeployment: QuickBattleDeployment(
              groups: [
                QuickBattleGroup(
                  lane: QuickBattleLane.center,
                  line: QuickBattleLine.front,
                  unitIds: ['a1'],
                  cohesion: 1,
                ),
              ],
            ),
            defenderDeployment: QuickBattleDeployment(
              groups: [
                QuickBattleGroup(
                  lane: QuickBattleLane.center,
                  line: QuickBattleLine.front,
                  unitIds: ['d1'],
                  cohesion: 1,
                ),
              ],
            ),
          ),
        ),
      );

      final Text attacker =
          tester.widget<Text>(find.text('Attacker'));
      final Text defender =
          tester.widget<Text>(find.text('Defender'));
      expect(attacker.style?.color, isNot(EditorialMonoclePalette.muted),
          reason:
              'Attacker header uses titleMedium (not the --muted row color).');
      expect(defender.style?.color, isNot(EditorialMonoclePalette.muted),
          reason:
              'Defender header uses titleMedium (not the --muted row color).');
    });

    testWidgets('cohesion suffix omitted when cohesion <= 0', (tester) async {
      await tester.pumpWidget(
        frame(
          const QuickBattleDeploymentView(
            attackerDeployment: QuickBattleDeployment(
              groups: [
                QuickBattleGroup(
                  lane: QuickBattleLane.center,
                  line: QuickBattleLine.front,
                  unitIds: ['a1'],
                  cohesion: 0,
                ),
              ],
            ),
            defenderDeployment: QuickBattleDeployment(
              groups: [],
            ),
          ),
        ),
      );

      expect(find.text('Center Front: 1 units'), findsOneWidget);
      expect(find.textContaining('Cohesion'), findsNothing);
    });
  });
}
