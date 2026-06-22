import 'package:colonizethis_app/package_logger.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';
import 'package:jenny/jenny.dart';
import 'package:jenny/src/structure/line_content.dart';

import 'package:colonizethis_app/features/game/dialogue/ct_dialogue_view.dart';

void main() {
  suppressLogsForTests();

  test(
    'CtDialogueView advanceLine completes line future and clears state',
    () async {
      final view = CtDialogueView(logger: packageLogger('dialogue'));

      var stateCalls = 0;
      view.onStateChanged = (_, _) => stateCalls++;

      final line = DialogueLine(content: LineContent('Hello world'));

      final resultFuture = view.onLineStart(line);
      expect(view.currentLine, isNotNull);
      expect(view.currentLine!.text, 'Hello world');
      expect(stateCalls, 1);

      // contextLine mirrors the active line while it is presented (#3628).
      expect(view.contextLine, isNotNull);
      expect(view.contextLine!.text, 'Hello world');

      view.advanceLine();
      final result = await resultFuture;
      expect(result, isTrue);

      expect(view.currentLine, isNull);
      expect(view.currentChoice, isNull);
      // contextLine is retained through the transient null state so consumers
      // keep the message visible while the next Jenny event is dispatched.
      expect(view.contextLine, isNotNull);
      expect(view.contextLine!.text, 'Hello world');
      // second state callback after advancing.
      expect(stateCalls, 2);
    },
  );

  test('CtDialogueView retains contextLine through choice and clears on select '
      '(#3628 combined line+choice)', () async {
    final view = CtDialogueView(logger: packageLogger('dialogue'));

    // Present a line, advance it, then present the following choice.
    final line = DialogueLine(content: LineContent('Narrative before choice'));
    final lineFuture = view.onLineStart(line);
    view.advanceLine();
    await lineFuture;

    final choice = DialogueChoice([
      DialogueOption(content: LineContent('Continue')),
    ]);
    final indexFuture = view.onChoiceStart(choice);

    // While the choice is active the immediately-preceding line is retained so
    // the overlay can render the narrative above the option button(s).
    expect(view.currentLine, isNull);
    expect(view.currentChoice, isNotNull);
    expect(view.contextLine, isNotNull);
    expect(view.contextLine!.text, 'Narrative before choice');

    view.selectOption(0);
    final index = await indexFuture;
    expect(index, 0);

    // Once the choice resolves the retained line is cleared so a later choice
    // without a preceding line does not show stale narrative.
    expect(view.currentChoice, isNull);
    expect(view.contextLine, isNull);
  });

  test(
    'CtDialogueView contextLine reflects only the immediately preceding line '
    'in a multi-line node (#3628)',
    () async {
      final view = CtDialogueView(logger: packageLogger('dialogue'));

      final first = view.onLineStart(DialogueLine(content: LineContent('L1')));
      view.advanceLine();
      await first;
      expect(view.contextLine!.text, 'L1');

      final second = view.onLineStart(DialogueLine(content: LineContent('L2')));
      expect(view.contextLine!.text, 'L2');
      view.advanceLine();
      await second;

      // L2 (not L1) accompanies the choice that follows the second line.
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

  test(
    'CtDialogueView onDialogueFinish clears state and signals nulls',
    () async {
      final view = CtDialogueView(logger: packageLogger('dialogue'));

      var nullCalls = 0;
      view.onStateChanged = (line, choice) {
        if (line == null && choice == null) nullCalls++;
      };

      // Drive a state first.
      final line = DialogueLine(content: LineContent('Transient'));
      final future = view.onLineStart(line);
      view.advanceLine();
      await future;

      expect(nullCalls, greaterThanOrEqualTo(1));

      // contextLine is retained after the line advance, then cleared on finish.
      expect(view.contextLine, isNotNull);

      view.onDialogueFinish();
      expect(nullCalls, greaterThanOrEqualTo(2));
      expect(view.currentLine, isNull);
      expect(view.currentChoice, isNull);
      expect(view.contextLine, isNull);
    },
  );
}
