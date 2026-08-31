/// Pins SPEC/ui/ct-dialogue-view.md (Refs #2753, #4305).
library;

import 'package:colonizethis_app/features/game/widgets/dialogue/ct_dialogue_view.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';
import 'package:jenny/jenny.dart';

import 'yarn_test_fixtures.dart';

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
        project.parse(kYarnTraceStory);
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
        project.parse(kYarnTraceStory);
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
}
