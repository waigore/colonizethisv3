import 'dart:async';

import 'package:colonizethis_app/package_logger.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';
import 'package:jenny/jenny.dart';
import 'package:jenny/src/structure/line_content.dart';

import 'package:colonizethis_app/features/game/widgets/dialogue/ct_dialogue_view.dart';

import 'ct_dialogue_view_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  test(
    'CtDialogueView advanceLine completes line future and clears state',
    () async {
      final view = CtDialogueView(logger: packageLogger('dialogue'));

      var stateCalls = 0;
      view.onStateChanged = (_, _) => stateCalls++;

      final line = ctDialogueViewLine('Hello world');

      final resultFuture = view.onLineStart(line);
      expect(view.currentLine, isNotNull);
      expect(view.currentLine!.text, 'Hello world');
      expect(stateCalls, 1);
      expect(view.contextLine, isNotNull);
      expect(view.contextLine!.text, 'Hello world');

      view.advanceLine();
      final result = await resultFuture;
      expect(result, isTrue);

      expect(view.currentLine, isNull);
      expect(view.currentChoice, isNull);
      expect(view.contextLine, isNotNull);
      expect(view.contextLine!.text, 'Hello world');
      expect(stateCalls, 2);
    },
  );

  test('CtDialogueView retains contextLine through choice and clears on select '
      '(#3628 combined line+choice)', () async {
    final view = CtDialogueView(logger: packageLogger('dialogue'));

    final line = ctDialogueViewLine('Narrative before choice');
    final lineFuture = view.onLineStart(line);
    view.advanceLine();
    await lineFuture;

    final choice = DialogueChoice([
      DialogueOption(content: LineContent('Continue')),
    ]);
    final indexFuture = view.onChoiceStart(choice);

    expect(view.currentLine, isNull);
    expect(view.currentChoice, isNotNull);
    expect(view.contextLine, isNotNull);
    expect(view.contextLine!.text, 'Narrative before choice');

    view.selectOption(0);
    final index = await indexFuture;
    expect(index, 0);

    expect(view.currentChoice, isNull);
    expect(view.contextLine, isNull);
  });

  test(
    'CtDialogueView contextLine reflects only the immediately preceding line '
    'in a multi-line node (#3628)',
    () async {
      final view = CtDialogueView(logger: packageLogger('dialogue'));

      final first = view.onLineStart(ctDialogueViewLine('L1'));
      view.advanceLine();
      await first;
      expect(view.contextLine!.text, 'L1');

      final second = view.onLineStart(ctDialogueViewLine('L2'));
      expect(view.contextLine!.text, 'L2');
      view.advanceLine();
      await second;

      final choice = DialogueChoice([
        DialogueOption(content: LineContent('Continue')),
      ]);
      view.onChoiceStart(choice);
      expect(view.contextLine!.text, 'L2');
    },
  );

  test(
    'CtDialogueView selectOption completes choice future with index',
    () async {
      final view = CtDialogueView(logger: packageLogger('dialogue'));

      final choice = DialogueChoice([
        DialogueOption(content: LineContent('Option A')),
        DialogueOption(content: LineContent('Option B')),
      ]);

      final indexFuture = view.onChoiceStart(choice);
      expect(view.currentChoice, isNotNull);
      expect(view.currentChoice!.options.length, 2);

      view.selectOption(1);
      final index = await indexFuture;
      expect(index, 1);

      expect(view.currentLine, isNull);
      expect(view.currentChoice, isNull);
    },
  );

  group('single line + single option collapse (#3628)', () {
    test(
      'onNodeStart marks a line before a single-option choice; '
      'onLineStart exposes the option label',
      () {
        final project = ctDialogueViewSingleOptionProject();
        final view = CtDialogueView(logger: packageLogger('dialogue'));
        final node = project.nodes['n']!;

        view.onNodeStart(node);
        view.onLineStart(ctDialogueViewFirstLine(node));

        expect(view.currentLine, isNotNull);
        expect(view.pendingSingleOptionLabel, 'I shall.');
      },
    );

    test('confirmCombinedLineOption advances the line and auto-selects the '
        'sole option without a second step', () async {
      final project = ctDialogueViewSingleOptionProject();
      final view = CtDialogueView(logger: packageLogger('dialogue'));
      final runner = DialogueRunner(
        yarnProject: project,
        dialogueViews: [view],
      );

      String? labelWhenLineShown;
      var choiceStepsRendered = 0;
      view.onStateChanged = (line, choice) {
        if (choice != null) choiceStepsRendered++;
        if (line != null &&
            view.pendingSingleOptionLabel != null &&
            labelWhenLineShown == null) {
          labelWhenLineShown = view.pendingSingleOptionLabel;
          scheduleMicrotask(view.confirmCombinedLineOption);
        }
      };

      await runner.startDialogue('n');

      expect(labelWhenLineShown, 'I shall.');
      expect(choiceStepsRendered, 0);
      expect(view.currentLine, isNull);
      expect(view.currentChoice, isNull);
      expect(view.contextLine, isNull);
      expect(view.pendingSingleOptionLabel, isNull);
    });

    test('multi-line node collapses only the final line before the option',
        () {
      final project = ctDialogueViewMultiLineProject();
      final view = CtDialogueView(logger: packageLogger('dialogue'));
      final node = project.nodes['n']!;
      final entries = node.toList(growable: false);
      final line1 = (entries[0] as DialogueLine)..evaluate();
      final line2 = (entries[1] as DialogueLine)..evaluate();

      view.onNodeStart(node);
      view.onLineStart(line1);
      expect(view.pendingSingleOptionLabel, isNull);
      view.advanceLine();
      view.onLineStart(line2);
      expect(view.pendingSingleOptionLabel, 'Continue');
    });

    test('a choice with two or more options never collapses', () {
      final project = ctDialogueViewMultiChoiceProject();
      final view = CtDialogueView(logger: packageLogger('dialogue'));
      final node = project.nodes['n']!;

      view.onNodeStart(node);
      view.onLineStart(ctDialogueViewFirstLine(node));

      expect(view.pendingSingleOptionLabel, isNull);
    });
  });

  test(
    'CtDialogueView onDialogueFinish clears state and signals nulls',
    () async {
      final view = CtDialogueView(logger: packageLogger('dialogue'));

      var nullCalls = 0;
      view.onStateChanged = (line, choice) {
        if (line == null && choice == null) nullCalls++;
      };

      final line = ctDialogueViewLine('Transient');
      final future = view.onLineStart(line);
      view.advanceLine();
      await future;

      expect(nullCalls, greaterThanOrEqualTo(1));
      expect(view.contextLine, isNotNull);

      view.onDialogueFinish();
      expect(nullCalls, greaterThanOrEqualTo(2));
      expect(view.currentLine, isNull);
      expect(view.currentChoice, isNull);
      expect(view.contextLine, isNull);
    },
  );
}
