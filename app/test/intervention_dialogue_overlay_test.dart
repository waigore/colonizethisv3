import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/dialogue/intervention_dialogue_overlay.dart';
import 'package:colonizethis_app/widgets/ct_brass_divider.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingAssetBundle extends Fake implements AssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) {
    return Future.error(StateError('missing intervention yarn'));
  }
}

/// Minimal Jenny-valid yarn project covering every node id referenced by
/// `InterventionDialogueOverlay`. Each node is a single line so a single
/// advance moves Jenny past the node; this keeps the deterministic widget
/// tests independent of the production `assets/dialogue/intervention.yarn`
/// payload (which adds presentation-only `-> Continue` choices).
class _MinimalInterventionAssetBundle extends Fake implements AssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) {
    return Future.value(
      'title: DialoguePoint/intervention_intro\n'
      '---\n'
      'intro line\n'
      '===\n'
      '\n'
      'title: DialoguePoint/intervention_situation\n'
      '---\n'
      'situation line\n'
      '===\n'
      '\n'
      'title: DialoguePoint/intervention_reaction_intervene\n'
      '---\n'
      'react intervene\n'
      '===\n'
      '\n'
      'title: DialoguePoint/intervention_reaction_do_nothing\n'
      '---\n'
      'react do nothing\n'
      '===\n'
      '\n'
      'title: DialoguePoint/intervention_reaction_protest\n'
      '---\n'
      'react protest\n'
      '===\n',
    );
  }
}

Game _buildSinglePromptGame(String id) {
  return Game(
    id: id,
    worldState: const WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(),
      newWorld: RegionData(),
    ),
    players: const [
      Player(id: 'gp1', displayName: 'Human', isHuman: true, treasury: 0),
      Player(id: 'gp2', displayName: 'Aggressor', isHuman: false, treasury: 0),
    ],
    minorNations: const [
      MinorNation(id: 'minor1', displayName: 'Minor 1'),
    ],
  );
}

const _kSinglePrompt = [
  InterventionPrompt(
    aggressorGpId: 'gp2',
    defenderMinorOrTribeId: 'minor1',
    interveningGpId: 'gp1',
  ),
];

/// Returns the scrim color used by the `Material` widget that the overlay
/// stacks over `widget.child`. The overlay scrim is the unique `Material`
/// inside `InterventionDialogueOverlay`'s subtree whose color resolves to a
/// non-transparent, non-zero opacity value (the `Dialog` shell internally
/// uses a transparent Material).
Color _overlayScrimColor(WidgetTester tester) {
  final scrimMaterials = tester
      .widgetList<Material>(
        find.descendant(
          of: find.byType(InterventionDialogueOverlay),
          matching: find.byType(Material),
        ),
      )
      .where((m) {
        final c = m.color;
        return c != null && c.a > 0;
      })
      .toList();
  expect(
    scrimMaterials,
    isNotEmpty,
    reason: 'Overlay should mount a Material scrim above widget.child',
  );
  return scrimMaterials.first.color!;
}

void main() {
  suppressLogsForTests();

  testWidgets(
    'InterventionDialogueOverlay degraded path submits do-nothing decisions when Yarn fails',
    (WidgetTester tester) async {
      final game = _buildSinglePromptGame('iv_degraded');
      List<InterventionDecision>? captured;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemes.colonial,
          home: InterventionDialogueOverlay(
            game: game,
            prompts: _kSinglePrompt,
            skipIntroForTest: true,
            assetBundle: _FailingAssetBundle(),
            onDecisions: (d) => captured = d,
            child: const SizedBox.expand(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.textContaining('Could not load intervention dialogue'),
        findsOneWidget,
      );
      await tester.tap(find.text('Continue'));
      await tester.pump();

      expect(captured, isNotNull);
      expect(captured!, hasLength(1));
      expect(captured!.single.choice, InterventionChoice.doNothing);
      expect(captured!.single.aggressorGpId, 'gp2');
      expect(captured!.single.defenderMinorOrTribeId, 'minor1');
      expect(captured!.single.interveningGpId, 'gp1');
    },
  );

  testWidgets(
    'InterventionDialogueOverlay degraded panel scrim resolves to dialogScrim token',
    (WidgetTester tester) async {
      final game = _buildSinglePromptGame('iv_degraded_scrim');
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemes.editorialMonocle,
          home: InterventionDialogueOverlay(
            game: game,
            prompts: _kSinglePrompt,
            skipIntroForTest: true,
            assetBundle: _FailingAssetBundle(),
            onDecisions: (_) {},
            child: const SizedBox.expand(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(_overlayScrimColor(tester), EditorialMonoclePalette.dialogScrim);
    },
  );

  testWidgets(
    'InterventionDialogueOverlay situation panel renders Pending Intervention title + CtBrassDivider',
    (WidgetTester tester) async {
      final game = _buildSinglePromptGame('iv_situation_title');
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemes.editorialMonocle,
          home: InterventionDialogueOverlay(
            game: game,
            prompts: _kSinglePrompt,
            skipIntroForTest: true,
            assetBundle: _MinimalInterventionAssetBundle(),
            onDecisions: (_) {},
            child: const SizedBox.expand(),
          ),
        ),
      );
      // Yarn load is async; pump until the situation line appears.
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.text('situation line').evaluate().isNotEmpty) break;
      }
      expect(
        find.text('situation line'),
        findsOneWidget,
        reason: 'Situation Yarn line should render before the player advances',
      );
      // Advance past the situation line to land in the awaiting-choice panel.
      await tester.tap(find.text('Continue'));
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.text('Pending Intervention').evaluate().isNotEmpty) break;
      }

      expect(
        find.text('Pending Intervention'),
        findsOneWidget,
        reason:
            'Situation + choices panel must show the editorial-monocle title',
      );
      expect(
        find.byType(CtBrassDivider),
        findsOneWidget,
        reason:
            'Situation + choices panel must show one CtBrassDivider beneath the title',
      );

      final titleStyle = tester
          .widget<Text>(find.text('Pending Intervention'))
          .style;
      expect(titleStyle, isNotNull);
      expect(titleStyle!.color, EditorialMonoclePalette.accent);
      expect(titleStyle.fontWeight, FontWeight.w600);
    },
  );

  testWidgets(
    'InterventionDialogueOverlay situation panel scrim resolves to dialogScrim token',
    (WidgetTester tester) async {
      final game = _buildSinglePromptGame('iv_situation_scrim');
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemes.editorialMonocle,
          home: InterventionDialogueOverlay(
            game: game,
            prompts: _kSinglePrompt,
            skipIntroForTest: true,
            assetBundle: _MinimalInterventionAssetBundle(),
            onDecisions: (_) {},
            child: const SizedBox.expand(),
          ),
        ),
      );
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.text('situation line').evaluate().isNotEmpty) break;
      }
      await tester.tap(find.text('Continue'));
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.text('Pending Intervention').evaluate().isNotEmpty) break;
      }

      expect(_overlayScrimColor(tester), EditorialMonoclePalette.dialogScrim);
    },
  );

  testWidgets(
    'InterventionDialogueOverlay Yarn-line panel does NOT render the title or CtBrassDivider',
    (WidgetTester tester) async {
      final game = _buildSinglePromptGame('iv_yarn_line_no_title');
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemes.editorialMonocle,
          home: InterventionDialogueOverlay(
            game: game,
            prompts: _kSinglePrompt,
            skipIntroForTest: true,
            assetBundle: _MinimalInterventionAssetBundle(),
            onDecisions: (_) {},
            child: const SizedBox.expand(),
          ),
        ),
      );
      // Pump until the situation Yarn line panel is on screen.
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.text('situation line').evaluate().isNotEmpty) break;
      }

      expect(find.text('situation line'), findsOneWidget);
      // Title + divider must only render in the awaiting-choice panel.
      expect(find.text('Pending Intervention'), findsNothing);
      expect(find.byType(CtBrassDivider), findsNothing);
    },
  );
}
