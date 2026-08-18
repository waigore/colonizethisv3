// Widget golden for the Tree-opened finish-time line (Refs #4511).
//
// SPEC: SPEC/ui/tech-tree-widget.md § Description dialog (Finish-time).

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/technology/tech_tree_finish_line.dart';
import 'package:colonizethis_app/features/game/widgets/technology/tech_tree_widget.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';
import 'panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  testWidgets('golden: Tree dialog Completes next turn finish-time line', (
    tester,
  ) async {
    const boundaryKey = ValueKey<String>('tech_tree_finish_line');
    final base = buildTechnologyPanelTestGame();
    final player = base.players.first.copyWith(
      treasury: 2000,
      researchSlots: 3,
      researchSlotAssignments: const {
        0: ResearchSlotAssignment(
          techId: kTechIdSawMill,
          funding: ResearchFundingLevel.medium,
        ),
      },
      researchProgressByTechId: const {kTechIdSawMill: 1600},
    );
    final game = base.copyWith(players: [player, ...base.players.skip(1)]);

    await pumpGoldenHost(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: const Size(420, 700),
      settle: false,
      includeLocalizations: true,
      scaffoldBackgroundColor:
          AppThemes.editorialMonocle.scaffoldBackgroundColor,
      child: TechTreeWidget(
        game: game,
        player: player,
        onOrdersChanged: (_) {},
      ),
    );
    final node = find.text(techDisplayName(kTechIdSawMill)).first;
    await tester.ensureVisible(node);
    await tester.tap(node);
    await pumpForGolden(tester);

    expect(tester.takeException(), isNull);
    expect(find.byKey(TechTreeFinishLine.lineKey), findsOneWidget);

    await expectLater(
      find.byType(CtDialogShell),
      matchesGoldenFile('goldens/tech_tree_finish_line_completes_next.png'),
    );
  });
}
