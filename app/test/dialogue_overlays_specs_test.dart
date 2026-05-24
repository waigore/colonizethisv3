/// Pins SPEC/ui contracts for the dialogue Jenny-adapter and the game-start
/// intro overlay.
///
/// Tracks:
///
/// - `SPEC/ui/ct-dialogue-view.md` (Jenny `DialogueView` subclass that drives
///   line / choice presentation via `onStateChanged`, `advanceLine`,
///   `selectOption`).
/// - `SPEC/ui/game-start-intro-overlay.md` (modal blocking overlay that runs
///   the `game_start_intro` Yarn node and notifies the host via
///   `onDismissed`).
///
/// Refs GitHub #2753.
library;

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/dialogue/ct_dialogue_view.dart';
import 'package:colonizethis_app/features/game/dialogue/game_start_intro_overlay.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jenny/jenny.dart';

class _InlineYarnAssetBundle extends Fake implements AssetBundle {
  _InlineYarnAssetBundle(this._text);

  final String _text;

  @override
  Future<String> loadString(String key, {bool cache = true}) {
    return Future.value(_text);
  }
}

class _MissingNodeAssetBundle extends Fake implements AssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) {
    return Future.value('title: not_the_intro\n---\nIrrelevant.\n===\n');
  }
}

const String _kIntroYarn = '''
title: game_start_intro
---
The age of imperialism draweth nigh.
-> I shall.
===
''';

const String _kTraceYarn = '''
title: trace_story
---
First line.
-> Continue
-> Stop
===
''';

Future<void> _pumpUntilSettled(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Widget _wrapIntroOverlay({
  required AssetBundle bundle,
  required VoidCallback onDismissed,
  Key? childKey,
}) {
  return MaterialApp(
    theme: AppThemes.colonial,
    locale: const Locale('en'),
    supportedLocales: const [Locale('en')],
    localizationsDelegates: const [
      // Reuse Material delegates so appL10n resolves english strings.
    ],
    home: Scaffold(
      body: GameStartIntroOverlay(
        onDismissed: onDismissed,
        assetBundle: bundle,
        child: SizedBox.expand(
          key: childKey,
          child: const Center(child: Text('child-content')),
        ),
      ),
    ),
  );
}

void main() {
  suppressLogsForTests();

  group('CtDialogueView (SPEC/ui/ct-dialogue-view.md)', () {
    test(
      'freshly constructed view exposes null line and choice, no completers',
      () {
        final view = CtDialogueView();
        expect(view.currentLine, isNull);
        expect(view.currentChoice, isNull);
        view.advanceLine();
        view.selectOption(0);
      },
    );

    test(
      'driving a Yarn project end-to-end transitions line -> choice -> finish '
      'and notifies onStateChanged at each boundary',
      () async {
        final project = YarnProject();
        project.parse(_kTraceYarn);
        final view = CtDialogueView();
        final transitions = <(String, String)>[];
        view.onStateChanged = (line, choice) {
          transitions.add((
            line == null ? 'null' : 'line',
            choice == null ? 'null' : 'choice',
          ));
        };

        final runner = DialogueRunner(
          yarnProject: project,
          dialogueViews: [view],
        );
        final fut = runner.startDialogue('trace_story');

        await Future<void>.delayed(const Duration(milliseconds: 1));
        expect(view.currentLine, isNotNull);
        expect(view.currentChoice, isNull);
        view.advanceLine();

        await Future<void>.delayed(const Duration(milliseconds: 1));
        expect(view.currentChoice, isNotNull);
        expect(view.currentLine, isNull);
        view.selectOption(0);

        await fut;

        expect(view.currentLine, isNull);
        expect(view.currentChoice, isNull);
        expect(
          transitions,
          containsAllInOrder(<(String, String)>[
            ('line', 'null'),
            ('null', 'null'),
            ('null', 'choice'),
            ('null', 'null'),
          ]),
        );
      },
    );

    test(
      'advanceLine and selectOption are idempotent (second call is a no-op)',
      () async {
        final project = YarnProject();
        project.parse(_kTraceYarn);
        final view = CtDialogueView();
        final runner = DialogueRunner(
          yarnProject: project,
          dialogueViews: [view],
        );
        final fut = runner.startDialogue('trace_story');

        await Future<void>.delayed(const Duration(milliseconds: 1));
        view.advanceLine();
        view.advanceLine();

        await Future<void>.delayed(const Duration(milliseconds: 1));
        view.selectOption(1);
        view.selectOption(0);

        await fut;
      },
    );
  });

  group('GameStartIntroOverlay (SPEC/ui/game-start-intro-overlay.md)', () {
    testWidgets(
      'with a valid Yarn intro: renders shell over child then dismisses '
      'after the dialogue finishes',
      (WidgetTester tester) async {
        var dismissedCount = 0;
        const childKey = Key('intro_child');

        await tester.pumpWidget(
          _wrapIntroOverlay(
            bundle: _InlineYarnAssetBundle(_kIntroYarn),
            onDismissed: () => dismissedCount++,
            childKey: childKey,
          ),
        );

        await _pumpUntilSettled(tester);

        expect(find.byKey(childKey), findsOneWidget);
        expect(find.byType(CtDialogShell), findsOneWidget);
        expect(find.text('The age of imperialism draweth nigh.'), findsOneWidget);
        expect(find.byType(CtNinePatchButton), findsOneWidget);

        await tester.tap(find.byType(CtNinePatchButton));
        await _pumpUntilSettled(tester);
        expect(find.text('I shall.'), findsOneWidget);

        await tester.tap(find.text('I shall.'));
        await _pumpUntilSettled(tester);

        expect(dismissedCount, 1);
        expect(find.byType(CtDialogShell), findsNothing);
        expect(find.byKey(childKey), findsOneWidget);
      },
    );

    testWidgets(
      'with a Yarn asset missing the intro node: surfaces the error '
      'affordance and Continue still dismisses',
      (WidgetTester tester) async {
        var dismissedCount = 0;

        await tester.pumpWidget(
          _wrapIntroOverlay(
            bundle: _MissingNodeAssetBundle(),
            onDismissed: () => dismissedCount++,
          ),
        );

        await _pumpUntilSettled(tester);

        expect(find.byType(CtDialogShell), findsOneWidget);
        expect(find.byType(CtNinePatchButton), findsOneWidget);

        await tester.tap(find.byType(CtNinePatchButton));
        await _pumpUntilSettled(tester);

        expect(dismissedCount, 1);
      },
    );
  });
}
