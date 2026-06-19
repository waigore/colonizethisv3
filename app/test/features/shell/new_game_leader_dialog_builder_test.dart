import 'dart:io';

import 'package:colonizethis_app/features/shell/new_game_leader_dialog_builder.dart';
import 'package:colonizethis_app/features/shell/new_game_leader_selection_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildNewGameLeaderSelectionDialog (Refs #3546)', () {
    testWidgets(
      'constructs a NewGameLeaderSelectionDialog from a ProviderScope context',
      (tester) async {
        late BuildContext captured;
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Builder(
                builder: (ctx) {
                  captured = ctx;
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );

        final Widget built = buildNewGameLeaderSelectionDialog(captured, null);

        expect(built, isA<NewGameLeaderSelectionDialog>());
      },
    );
  });

  group('core→shell layering (Refs #3546)', () {
    Iterable<String> importLinesOf(String relativePath) => File(relativePath)
        .readAsLinesSync()
        .map((l) => l.trim())
        .where((l) => l.startsWith('import '));

    test(
      'app_event_handler_scope.dart has no features/shell import',
      () {
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
      },
    );

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
