import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'dart:io';

import 'package:colonizethis_app/features/shell/new_game_leader_dialog_builder.dart';
import 'package:colonizethis_app/features/shell/new_game_leader_selection_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  suppressLogsForTests();

  group('buildNewGameLeaderSelectionDialog (Refs #3546)', () {
    testWidgets(
      'factory threads the navigator key and builds a leader-selection dialog',
      (tester) async {
        late BuildContext captured;
        final navigatorKey = GlobalKey<NavigatorState>();
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              navigatorKey: navigatorKey,
              home: Builder(
                builder: (ctx) {
                  captured = ctx;
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );

        final builder = buildNewGameLeaderSelectionDialog(navigatorKey);
        final Widget built = builder(captured, null);

        expect(built, isA<NewGameLeaderSelectionDialog>());
      },
    );

    test(
      'shell builder file does not read the global appNavigatorKey in code',
      () {
        // Strip line comments so a doc-comment mention of the symbol does not
        // false-positive; the lint (repo.app_event_bus_decoupling) only flags
        // actual code access.
        final codeOnly =
            File('lib/features/shell/new_game_leader_dialog_builder.dart')
                .readAsLinesSync()
                .where((l) => !l.trimLeft().startsWith('///'))
                .where((l) => !l.trimLeft().startsWith('//'))
                .join('\n');

        expect(
          codeOnly.contains('appNavigatorKey'),
          isFalse,
          reason:
              'features/shell must thread an explicit GlobalKey<NavigatorState> '
              '(repo.app_event_bus_decoupling confines appNavigatorKey to '
              'core/services + app.dart).',
        );
      },
    );
  });

  group('core→shell layering (Refs #3546)', () {
    Iterable<String> importLinesOf(String relativePath) => File(relativePath)
        .readAsLinesSync()
        .map((l) => l.trim())
        .where((l) => l.startsWith('import '));

    test('app_event_handler_scope.dart has no features/shell import', () {
      final shellImports = importLinesOf(
        'lib/core/services/app_event_handler_scope.dart',
      ).where((l) => l.contains('features/shell/')).toList();

      expect(
        shellImports,
        isEmpty,
        reason:
            'core/services must not import features/shell; inject feature '
            'dialog builders via AppEventHandlerScope.extraDialogBuilders at '
            'the composition root instead.',
      );
    });

    test(
      'dialog-builders part file neither imports nor references features/shell',
      () {
        final source = File(
          'lib/core/services/app_event_handler_scope_dialog_builders.dart',
        ).readAsStringSync();
        final shellImports = importLinesOf(
          'lib/core/services/app_event_handler_scope_dialog_builders.dart',
        ).where((l) => l.contains('features/shell/')).toList();

        expect(shellImports, isEmpty);
        expect(source.contains('NewGameLeaderSelectionDialog'), isFalse);
      },
    );
  });
}
