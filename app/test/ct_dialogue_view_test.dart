import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';
import 'package:jenny/jenny.dart';
import 'package:jenny/src/structure/line_content.dart';

import 'package:colonizethis_app/features/game/dialogue/ct_dialogue_view.dart';

void main() {
  suppressLogsForTests();

  test('CtDialogueView advanceLine completes line future and clears state',
      () async {
    final view = CtDialogueView(logger: appLogger('dialogue'));

    var stateCalls = 0;
    view.onStateChanged = (_, __) => stateCalls++;

    final line = DialogueLine(
      content: LineContent('Hello world'),
    );

    final resultFuture = view.onLineStart(line);
    expect(view.currentLine, isNotNull);
    expect(view.currentLine!.text, 'Hello world');
    expect(stateCalls, 1);

    view.advanceLine();
    final result = await resultFuture;
    expect(result, isTrue);

    expect(view.currentLine, isNull);
    expect(view.currentChoice, isNull);
    // second state callback after advancing.
    expect(stateCalls, 2);
  });

  test('CtDialogueView selectOption completes choice future with index',
      () async {
    final view = CtDialogueView(logger: appLogger('dialogue'));

    var lastIndex = -1;
    view.onStateChanged = (line, choice) {
      if (choice != null && choice.options.isNotEmpty) {
        lastIndex = 0;
      }
    };

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
  });

  test('CtDialogueView onDialogueFinish clears state and signals nulls',
      () async {
    final view = CtDialogueView(logger: appLogger('dialogue'));

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

    view.onDialogueFinish();
    expect(nullCalls, greaterThanOrEqualTo(2));
    expect(view.currentLine, isNull);
    expect(view.currentChoice, isNull);
  });
}

