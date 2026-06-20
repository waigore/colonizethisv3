import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/flame/victory_overlay.dart';
import 'package:colonizethis_app/widgets/ct_brass_divider.dart';
import 'package:colonizethis_app/widgets/ct_gradients.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  late ct_models.Game game;
  late String winnerPlayerId;
  late ct_models.AppEventBus victoryTestBus;

  setUp(() {
    ct_models.AppEventBus.reset();
    victoryTestBus = ct_models.AppEventBus.create();
    game = getDebugInitGameResult().game;
    winnerPlayerId = game.players.first.id;
  });

  tearDown(() {
    ct_models.AppEventBus.reset();
  });

  Widget buildVictoryRoute({
    required ct_models.VictoryState victory,
    ct_models.AppEventBus? bus,
  }) {
    return Scaffold(
      body: Stack(
        children: [
          VictoryOverlay(
            game: game,
            victory: victory,
            bus: bus ?? victoryTestBus,
          ),
        ],
      ),
    );
  }

  testWidgets('VictoryOverlay renders victory label and winner sentence', (
    WidgetTester tester,
  ) async {
    final victory = ct_models.VictoryState(
      winnerPlayerId: winnerPlayerId,
      type: ct_models.VictoryType.military,
      turnNumber: 12,
    );

    await tester.pumpWidget(
      MaterialApp(home: buildVictoryRoute(victory: victory)),
    );
    await tester.pumpAndSettle();

    expect(find.text('MILITARY VICTORY'), findsOneWidget);
    expect(find.textContaining('wins on turn 12'), findsOneWidget);
  });

  testWidgets('VictoryOverlay "View final state" dismisses overlay', (
    WidgetTester tester,
  ) async {
    final victory = ct_models.VictoryState(
      winnerPlayerId: winnerPlayerId,
      type: ct_models.VictoryType.military,
      turnNumber: 1,
    );

    await tester.pumpWidget(
      MaterialApp(home: buildVictoryRoute(victory: victory)),
    );
    await tester.pumpAndSettle();

    expect(find.text('MILITARY VICTORY'), findsOneWidget);
    await tester.tap(find.text('View final state'));
    await tester.pumpAndSettle();
    expect(find.text('MILITARY VICTORY'), findsNothing);
  });

  testWidgets('VictoryOverlay "Return to main menu" emits NavigateToShellEvent', (
    WidgetTester tester,
  ) async {
    final victory = ct_models.VictoryState(
      winnerPlayerId: winnerPlayerId,
      type: ct_models.VictoryType.military,
      turnNumber: 3,
    );

    ct_models.NavigateToShellEvent? emitted;
    final sub = victoryTestBus.on<ct_models.NavigateToShellEvent>().listen(
      (e) => emitted = e,
    );
    addTearDown(sub.cancel);

    await tester.pumpWidget(
      MaterialApp(home: buildVictoryRoute(victory: victory, bus: victoryTestBus)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Return to main menu'));
    await tester.pump();

    expect(emitted, isA<ct_models.NavigateToShellEvent>());
  });

  testWidgets('VictoryPanel uses first player when winner id is unknown', (
    WidgetTester tester,
  ) async {
    final victory = ct_models.VictoryState(
      winnerPlayerId: 'nonexistent-player',
      type: ct_models.VictoryType.military,
      turnNumber: 45,
    );
    final fallbackName = game.players.first.displayName;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VictoryPanel(
            game: game,
            victory: victory,
            bus: victoryTestBus,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining(fallbackName), findsOneWidget);
    expect(find.textContaining('turn 45'), findsOneWidget);
    expect(find.byType(CtNinePatchButton), findsNWidgets(2));
  });

  testWidgets(
    'VictoryOverlay scrim resolves to EditorialMonoclePalette.dialogScrim',
    (WidgetTester tester) async {
      final victory = ct_models.VictoryState(
        winnerPlayerId: winnerPlayerId,
        type: ct_models.VictoryType.military,
        turnNumber: 7,
      );

      await tester.pumpWidget(
        MaterialApp(home: buildVictoryRoute(victory: victory)),
      );
      await tester.pumpAndSettle();

      // The overlay's scrim Material must resolve to the canonical
      // --dialog-scrim token, not Colors.black54.
      final Iterable<Material> scrimMaterials = tester
          .widgetList<Material>(
            find.descendant(
              of: find.byType(VictoryOverlay),
              matching: find.byType(Material),
            ),
          )
          .where((m) => m.color == EditorialMonoclePalette.dialogScrim);
      expect(scrimMaterials, isNotEmpty,
          reason:
              'VictoryOverlay must wash the screen with the canonical '
              '--dialog-scrim token via CtFullScreenDialogueShell, not '
              'Colors.black54 or a hex literal.');
    },
  );

  testWidgets(
    'VictoryPanel surface paints CtGradients.victoryPanelGradient under a 2px '
    '--accent border',
    (WidgetTester tester) async {
      final victory = ct_models.VictoryState(
        winnerPlayerId: winnerPlayerId,
        type: ct_models.VictoryType.military,
        turnNumber: 50,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VictoryPanel(
              game: game,
              victory: victory,
              bus: victoryTestBus,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final Iterable<DecoratedBox> decoratedBoxes = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(VictoryPanel),
              matching: find.byType(DecoratedBox),
            ),
          )
          .where((box) {
            final decoration = box.decoration;
            if (decoration is! BoxDecoration) return false;
            if (decoration.gradient != CtGradients.victoryPanelGradient) {
              return false;
            }
            final BoxBorder? border = decoration.border;
            if (border is! Border) return false;
            return border.top.width == VictoryPanel.borderWidth &&
                border.top.color == EditorialMonoclePalette.accent;
          });
      expect(decoratedBoxes, isNotEmpty,
          reason:
              'VictoryPanel must paint the brass-bordered ceremonial surface '
              'with CtGradients.victoryPanelGradient + a 2px --accent border.');
    },
  );

  testWidgets('VictoryPanel renders a CtBrassDivider between title and body',
      (WidgetTester tester) async {
    final victory = ct_models.VictoryState(
      winnerPlayerId: winnerPlayerId,
      type: ct_models.VictoryType.military,
      turnNumber: 30,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VictoryPanel(
            game: game,
            victory: victory,
            bus: victoryTestBus,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CtBrassDivider), findsOneWidget);
  });

  testWidgets('VictoryPanel renders no Material Elevated/Text/Outlined buttons',
      (WidgetTester tester) async {
    final victory = ct_models.VictoryState(
      winnerPlayerId: winnerPlayerId,
      type: ct_models.VictoryType.military,
      turnNumber: 4,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VictoryPanel(
            game: game,
            victory: victory,
            bus: victoryTestBus,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ElevatedButton), findsNothing);
    expect(find.byType(TextButton), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.byType(CtNinePatchButton), findsNWidgets(2));
  });
}
