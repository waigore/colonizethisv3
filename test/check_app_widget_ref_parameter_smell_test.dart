import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_app_widget_ref_parameter_smell.dart';

/// Tests for `runCheckAppWidgetRefParameterSmell` (Refs #3483).
void main() {
  group('positive violations', () {
    test('flags top-level helper with WidgetRef parameter', () {
      final root = _writeAppFile(
        'app/lib/features/game/widgets/bad_helper.dart',
        '''
import 'package:flutter_riverpod/flutter_riverpod.dart';

void syncSomething(WidgetRef ref, String id) {}
''',
      );
      final stderrLines = <String>[];
      final code = runCheckAppWidgetRefParameterSmell(
        root.path,
        err: stderrLines.add,
      );
      expect(code, 1);
      expect(
        stderrLines.join('\n'),
        contains('app/lib/features/game/widgets/bad_helper.dart:'),
      );
    });
  });

  group('negative cases', () {
    test('allows ConsumerWidget build method WidgetRef parameter', () {
      final root = _writeAppFile(
        'app/lib/features/game/widgets/good_widget.dart',
        '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GoodWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SizedBox();
  }
}
''',
      );
      expect(runCheckAppWidgetRefParameterSmell(root.path), 0);
    });

    test('allows Provider factory Ref callback parameter', () {
      final root = _writeAppFile(
        'app/lib/providers/good_provider.dart',
        '''
import 'package:flutter_riverpod/flutter_riverpod.dart';

final goodProvider = Provider<String>((ref) => 'ok');
''',
      );
      expect(runCheckAppWidgetRefParameterSmell(root.path), 0);
    });

    test('allows typedef callback contract with WidgetRef parameter', () {
      final root = _writeAppFile(
        'app/lib/providers/shell_contract_stub.dart',
        '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

typedef BodyBuilder = Widget Function(
  BuildContext context,
  WidgetRef ref,
  Game displayGame,
);
''',
      );
      expect(runCheckAppWidgetRefParameterSmell(root.path), 0);
    });

    test('honors line ignore for app_widget_ref_parameter_smell', () {
      final root = _writeAppFile(
        'app/lib/core/services/ignored_helper.dart',
        '''
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ignore: app_widget_ref_parameter_smell
void legacyHelper(WidgetRef ref) {}
''',
      );
      expect(runCheckAppWidgetRefParameterSmell(root.path), 0);
    });
  });
}

Directory _writeAppFile(String relativePath, String contents) {
  final root = Directory.systemTemp.createTempSync('ct_widget_ref_smell_');
  final file = File(p.join(root.path, relativePath));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(contents);
  addTearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });
  return root;
}
