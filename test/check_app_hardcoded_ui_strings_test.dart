import 'package:test/test.dart';

import '../tool/check_app_hardcoded_ui_strings.dart';

void main() {
  group('findHardcodedUiViolations', () {
    test('flags multiline Text string literal', () {
      const src = r'''
import 'package:flutter/material.dart';

class M extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      'Multi line hello',
    );
  }
}
''';
      final v = findHardcodedUiViolations('app/lib/x.dart', src);
      expect(v, isNotEmpty);
      expect(v.first.line, greaterThan(0));
    });

    test('allows two-character literal', () {
      const src = r'''
import 'package:flutter/material.dart';

class M extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text('OK');
}
''';
      expect(findHardcodedUiViolations('app/lib/x.dart', src), isEmpty);
    });

    test('allows non-literal first argument', () {
      const src = r'''
import 'package:flutter/material.dart';

class M extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = 1;
    return Text(l10n.toString());
  }
}
''';
      expect(findHardcodedUiViolations('app/lib/x.dart', src), isEmpty);
    });

    test('respects same-line ignore', () {
      const src = r'''
import 'package:flutter/material.dart';

class M extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Text('Nope', // ignore: avoid_hardcoded_strings_in_widgets
      );
}
''';
      expect(findHardcodedUiViolations('app/lib/x.dart', src), isEmpty);
    });

    test('respects ignore on previous line', () {
      const src = r'''
import 'package:flutter/material.dart';

class M extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // ignore: avoid_hardcoded_strings_in_widgets
    return Text('Nope');
  }
}
''';
      expect(findHardcodedUiViolations('app/lib/x.dart', src), isEmpty);
    });

    test('respects ignore_for_file', () {
      const src = r'''
// ignore_for_file: avoid_hardcoded_strings_in_widgets
import 'package:flutter/material.dart';

class M extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text('Nope');
}
''';
      expect(findHardcodedUiViolations('app/lib/x.dart', src), isEmpty);
    });

    test('flags string interpolation with static text', () {
      const src = r'''
import 'package:flutter/material.dart';

class M extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final x = 1;
    return Text('Hello $x');
  }
}
''';
      expect(findHardcodedUiViolations('app/lib/x.dart', src), isNotEmpty);
    });

    test('allows interpolation without static user text', () {
      const src = r'''
import 'package:flutter/material.dart';

class M extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final x = 'a';
    return Text('${x}');
  }
}
''';
      expect(findHardcodedUiViolations('app/lib/x.dart', src), isEmpty);
    });

    test('flags Tooltip message literal', () {
      const src = r'''
import 'package:flutter/material.dart';

class M extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Secret tip',
      child: Icon(Icons.info),
    );
  }
}
''';
      expect(findHardcodedUiViolations('app/lib/x.dart', src), isNotEmpty);
    });

    test('returns empty for non-app path', () {
      expect(
        findHardcodedUiViolations('packages/foo/lib/x.dart', "Text('Hi');"),
        isEmpty,
      );
    });
  });
}
