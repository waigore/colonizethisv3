import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_subscription_tracker.dart';

void main() {
  test('fails when app feature code stores subscriptions in a raw list', () {
    final tempDir = Directory.systemTemp.createTempSync(
      'check_subscription_tracker_fail_',
    );
    addTearDown(() => tempDir.deleteSync(recursive: true));
    final targetPath = p.join(
      tempDir.path,
      'app',
      'lib',
      'features',
      'game',
      'flame',
      'bad_listener.dart',
    );
    File(targetPath)
      ..createSync(recursive: true)
      ..writeAsStringSync('''
import 'dart:async';

final List<StreamSubscription<dynamic>> subscriptions = [];
''');

    final stderrLines = <String>[];
    final code = runCheckSubscriptionTracker(
      tempDir.path,
      err: stderrLines.add,
    );

    expect(code, 1);
    expect(
      stderrLines.join('\n'),
      contains(
        'use SubscriptionTracker instead of a raw StreamSubscription list',
      ),
    );
    expect(stderrLines.join('\n'), contains('bad_listener.dart:3'));
  });

  test('fails for inferred raw StreamSubscription list literals', () {
    final tempDir = Directory.systemTemp.createTempSync(
      'check_subscription_tracker_inferred_fail_',
    );
    addTearDown(() => tempDir.deleteSync(recursive: true));
    final targetPath = p.join(
      tempDir.path,
      'app',
      'lib',
      'features',
      'game',
      'bad_listener.dart',
    );
    File(targetPath)
      ..createSync(recursive: true)
      ..writeAsStringSync('''
import 'dart:async';

final subscriptions = <StreamSubscription<dynamic>>[];
''');

    final code = runCheckSubscriptionTracker(tempDir.path);

    expect(code, 1);
  });

  test('passes when app feature code uses SubscriptionTracker', () {
    final tempDir = Directory.systemTemp.createTempSync(
      'check_subscription_tracker_pass_',
    );
    addTearDown(() => tempDir.deleteSync(recursive: true));
    final targetPath = p.join(
      tempDir.path,
      'app',
      'lib',
      'features',
      'game',
      'good_listener.dart',
    );
    File(targetPath)
      ..createSync(recursive: true)
      ..writeAsStringSync('''
import 'package:colonizethis_app/core/services/subscription_tracker.dart';

final subscriptions = SubscriptionTracker();
''');

    final stdoutLines = <String>[];
    final code = runCheckSubscriptionTracker(
      tempDir.path,
      info: stdoutLines.add,
    );

    expect(code, 0);
    expect(stdoutLines.join('\n'), contains('no violations found'));
  });
}
