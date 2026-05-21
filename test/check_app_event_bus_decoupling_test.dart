import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_app_event_bus_decoupling.dart';

/// Tests for `runCheckAppEventBusDecoupling` (Refs #2626).
///
/// SPEC: `SPEC/program/app-ui-wiring.md` (coupling rules and "Local by design"
/// allow-list); `SPEC/program/app-event-bus.md` (`AppEventBus.create`).
void main() {
  group('AppEventBus() singleton check', () {
    test(
      'fails when production app/lib code constructs AppEventBus() directly',
      () {
        final root = _writeAppFile(
          'app/lib/features/game/widgets/bad_panel.dart',
          '''
import 'package:colonizethis_models/colonizethis_models.dart';

void emitDebug() {
  AppEventBus().emit(const Object());
}
''',
        );
        final stderrLines = <String>[];
        final code = runCheckAppEventBusDecoupling(
          root.path,
          err: stderrLines.add,
        );
        expect(code, 1);
        expect(
          stderrLines.join('\n'),
          contains('AppEventBus() singleton calls'),
        );
        expect(
          stderrLines.join('\n'),
          contains('app/lib/features/game/widgets/bad_panel.dart:4'),
        );
      },
    );

    test('ignores AppEventBus() under app/lib/widgetbook/', () {
      final root = _writeAppFile(
        'app/lib/widgetbook/catalog_demo.dart',
        '''
import 'package:colonizethis_models/colonizethis_models.dart';

final bus = AppEventBus();
''',
      );
      final stdoutLines = <String>[];
      final code = runCheckAppEventBusDecoupling(
        root.path,
        info: stdoutLines.add,
      );
      expect(code, 0);
      expect(stdoutLines.join('\n'), contains('no violations found'));
    });

    test('passes when production code uses AppEventBus.create()', () {
      final root = _writeAppFile(
        'app/lib/features/shell/good_flow.dart',
        '''
import 'package:colonizethis_models/colonizethis_models.dart';

final bus = AppEventBus.create();
''',
      );
      final code = runCheckAppEventBusDecoupling(root.path);
      expect(code, 0);
    });
  });

  group('appNavigatorKey choke-point check', () {
    test('fails when app/lib/providers/ reads appNavigatorKey.currentContext',
        () {
      final root = _writeAppFile(
        'app/lib/providers/leaky_provider.dart',
        '''
import '../app.dart' show appNavigatorKey;

void doStuff() {
  final ctx = appNavigatorKey.currentContext;
  if (ctx == null) return;
}
''',
      );
      final stderrLines = <String>[];
      final code = runCheckAppEventBusDecoupling(
        root.path,
        err: stderrLines.add,
      );
      expect(code, 1);
      expect(
        stderrLines.join('\n'),
        contains('appNavigatorKey property access'),
      );
      expect(
        stderrLines.join('\n'),
        contains('app/lib/providers/leaky_provider.dart:4'),
      );
    });

    test('fails when app/lib/features/ reads appNavigatorKey.currentState', () {
      final root = _writeAppFile(
        'app/lib/features/shell/leaky_flow.dart',
        '''
import 'package:colonizethis_app/app.dart' show appNavigatorKey;

void doStuff() {
  final state = appNavigatorKey.currentState;
  state?.pop();
}
''',
      );
      final stderrLines = <String>[];
      final code = runCheckAppEventBusDecoupling(
        root.path,
        err: stderrLines.add,
      );
      expect(code, 1);
      expect(
        stderrLines.join('\n'),
        contains('app/lib/features/shell/leaky_flow.dart:4'),
      );
    });

    test(
      'allows appNavigatorKey access under app/lib/core/services/',
      () {
        final root = _writeAppFile(
          'app/lib/core/services/some_service.dart',
          '''
import '../../app.dart' show appNavigatorKey;

void doStuff() {
  final ctx = appNavigatorKey.currentContext;
  if (ctx == null) return;
}
''',
        );
        final code = runCheckAppEventBusDecoupling(root.path);
        expect(code, 0);
      },
    );

    test('allows appNavigatorKey access in app/lib/app.dart itself', () {
      final root = _writeAppFile(
        'app/lib/app.dart',
        '''
import 'package:flutter/widgets.dart';

final appNavigatorKey = GlobalKey<NavigatorState>();

void boot() {
  final ctx = appNavigatorKey.currentContext;
  if (ctx == null) return;
}
''',
      );
      final code = runCheckAppEventBusDecoupling(root.path);
      expect(code, 0);
    });
  });

  group('features/ showDialog allow-list check', () {
    test(
      'fails when a new file under app/lib/features/ calls showDialog',
      () {
        final root = _writeAppFile(
          'app/lib/features/game/widgets/new_panel.dart',
          '''
import 'package:flutter/material.dart';

Future<void> open(BuildContext context) {
  return showDialog<void>(context: context, builder: (_) => const Text('x'));
}
''',
        );
        final stderrLines = <String>[];
        final code = runCheckAppEventBusDecoupling(
          root.path,
          err: stderrLines.add,
        );
        expect(code, 1);
        expect(
          stderrLines.join('\n'),
          contains(
            'showDialog / showModalBottomSheet in features/ outside the '
            'documented local-by-design allow-list',
          ),
        );
        expect(
          stderrLines.join('\n'),
          contains('app/lib/features/game/widgets/new_panel.dart:4'),
        );
      },
    );

    test(
      'fails when a new file under app/lib/features/ calls '
      'showModalBottomSheet',
      () {
        final root = _writeAppFile(
          'app/lib/features/game/widgets/new_sheet.dart',
          '''
import 'package:flutter/material.dart';

Future<void> open(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (_) => const Text('x'),
  );
}
''',
        );
        final code = runCheckAppEventBusDecoupling(root.path);
        expect(code, 1);
      },
    );

    test(
      'allows showDialog inside the documented local-by-design files',
      () {
        // `new_game_setup_flow.dart` is in the allow-list per
        // SPEC/program/app-ui-wiring.md § "Local by design".
        final root = _writeAppFile(
          'app/lib/features/shell/new_game_setup_flow.dart',
          '''
import 'package:flutter/material.dart';

Future<void> open(BuildContext context) {
  return showDialog<void>(context: context, builder: (_) => const Text('x'));
}
''',
        );
        final stdoutLines = <String>[];
        final code = runCheckAppEventBusDecoupling(
          root.path,
          info: stdoutLines.add,
        );
        expect(code, 0);
        expect(stdoutLines.join('\n'), contains('no violations found'));
      },
    );

    test('ignores showDialog outside features/ (e.g. shell widgets root)', () {
      final root = _writeAppFile(
        'app/lib/widgets/some_widget.dart',
        '''
import 'package:flutter/material.dart';

Future<void> open(BuildContext context) {
  return showDialog<void>(context: context, builder: (_) => const Text('x'));
}
''',
      );
      final code = runCheckAppEventBusDecoupling(root.path);
      expect(code, 0);
    });

    test('ignores method-target invocations like ref.showDialog(...)', () {
      // Sanity-check that the rule only flags the Flutter free functions, not
      // unrelated identifiers that happen to use the same name as a method on
      // another object.
      final root = _writeAppFile(
        'app/lib/features/game/widgets/method_target.dart',
        '''
class Wrapper {
  Future<void> showDialog() async {}
}

Future<void> open(Wrapper w) => w.showDialog();
''',
      );
      final code = runCheckAppEventBusDecoupling(root.path);
      expect(code, 0);
    });
  });
}

Directory _writeAppFile(String relativePath, String content) {
  final tempDir = Directory.systemTemp.createTempSync(
    'check_app_event_bus_decoupling_test_',
  );
  addTearDown(() => tempDir.deleteSync(recursive: true));
  final targetPath = p.join(tempDir.path, relativePath);
  File(targetPath)
    ..createSync(recursive: true)
    ..writeAsStringSync(content);
  return tempDir;
}
