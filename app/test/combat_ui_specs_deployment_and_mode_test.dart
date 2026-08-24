// Pins SPEC/ui combat dialog and sub-view contracts:
// - SPEC/ui/quick-battle-deployment-view.md
// - SPEC/ui/quick-battle-action-selector.md
// - SPEC/ui/combat-mode-choice-dialog.md
// Shared frames: combat_ui_specs_test_support.dart (Refs #4013, #4352).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';

import 'combat_ui_specs_test_support.dart';

void main() {
  suppressLogsForTests();

  group(
    'QuickBattleDeploymentView (SPEC/ui/quick-battle-deployment-view.md)',
    () {
      testWidgets('renders attacker and defender headers with custom names', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          combatUiSpecsFrame(
            combatUiSpecsDeploymentView(
              attackerGroups: [
                combatUiSpecsCenterFront(unitIds: const ['a1', 'a2', 'a3']),
              ],
              defenderGroups: [
                combatUiSpecsCenterFront(unitIds: const ['d1', 'd2']),
              ],
              attackerName: 'Castile',
              defenderName: 'England',
            ),
          ),
        );

        expect(find.text('Castile'), findsOneWidget);
        expect(find.text('England'), findsOneWidget);
        expect(find.text('Center Front: 3 units (Cohesion 3)'), findsOneWidget);
        expect(find.text('Center Front: 2 units (Cohesion 3)'), findsOneWidget);
      });

      testWidgets('omits cohesion suffix when cohesion is 0', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          combatUiSpecsFrame(
            combatUiSpecsDeploymentView(
              attackerGroups: [
                combatUiSpecsCenterFront(unitIds: const ['a1'], cohesion: 0),
              ],
              defenderGroups: [
                combatUiSpecsCenterFront(unitIds: const ['d1'], cohesion: 1),
              ],
            ),
          ),
        );

        expect(find.text('Center Front: 1 units'), findsOneWidget);
        expect(find.text('Center Front: 1 units (Cohesion 1)'), findsOneWidget);
      });

      testWidgets(
        'uses default Attacker / Defender headers when names are omitted',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            combatUiSpecsFrame(combatUiSpecsDeploymentView()),
          );

          expect(find.text('Attacker'), findsOneWidget);
          expect(find.text('Defender'), findsOneWidget);
        },
      );

      // Refs #2869 R14 + SPEC/ui/quick-battle-deployment-view.md § Layout.
      testWidgets(
        'group-row text resolves to --muted under dark and fallback themes',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            combatUiSpecsDarkFrame(
              combatUiSpecsDeploymentView(
                attackerGroups: [
                  combatUiSpecsCenterFront(unitIds: const ['a1', 'a2', 'a3']),
                ],
                defenderGroups: [
                  combatUiSpecsCenterFront(unitIds: const ['d1'], cohesion: 0),
                ],
              ),
            ),
          );
          expect(
            tester
                .widget<Text>(find.text('Center Front: 3 units (Cohesion 3)'))
                .style
                ?.color,
            EditorialMonoclePalette.muted,
          );
          expect(
            tester
                .widget<Text>(find.text('Center Front: 1 units'))
                .style
                ?.color,
            EditorialMonoclePalette.muted,
          );

          await tester.pumpWidget(
            combatUiSpecsFrame(
              combatUiSpecsDeploymentView(
                attackerGroups: [
                  combatUiSpecsCenterFront(unitIds: const ['a1'], cohesion: 2),
                ],
              ),
            ),
          );
          expect(
            tester
                .widget<Text>(find.text('Center Front: 1 units (Cohesion 2)'))
                .style
                ?.color,
            EditorialMonoclePalette.muted,
          );
        },
      );
    },
  );
}
