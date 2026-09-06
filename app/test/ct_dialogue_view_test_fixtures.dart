// Yarn/fixture helpers for CtDialogueView unit tests (Refs #4734 Slice H).

import 'package:jenny/jenny.dart';
import 'package:jenny/src/structure/line_content.dart';

DialogueLine ctDialogueViewFirstLine(Node node) {
  final entry = node.toList(growable: false).first;
  return (entry as DialogueLine)..evaluate();
}

YarnProject ctDialogueViewSingleOptionProject() => YarnProject()
  ..parse('''
title: n
---
The age of imperialism draweth nigh.
-> I shall.
===
''');

YarnProject ctDialogueViewMultiLineProject() => YarnProject()
  ..parse('''
title: n
---
Heavy tidings cross thy desk.
Each matter shall be judged in turn.
-> Continue
===
''');

YarnProject ctDialogueViewMultiChoiceProject() => YarnProject()
  ..parse('''
title: n
---
Choose thy path.
-> Onward
-> Retreat
===
''');

DialogueLine ctDialogueViewLine(String text) =>
    DialogueLine(content: LineContent(text));
