// Pins removal of the historical no-op `destTileSize` prop from
// `CtPanel` / `CtNinePatchButton` (Refs #4035 chrome densify).
//
// SPEC: SPEC/ui/buttons-nine-patch.md § Acceptance criteria;
// SPEC/ui/pixel-art-ui-catalog.md § CtPanel / CtNinePatchButton.

import 'dart:io';

import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_panel.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'app_shell_harness.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'positive: CtPanel and CtNinePatchButton mount without destTileSize',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        buildAppShell(
          child: Scaffold(
            body: Column(
              children: [
                const CtPanel(child: Text('panel')),
                CtNinePatchButton(
                  onPressed: () {},
                  child: const Text('button'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CtPanel), findsOneWidget);
      expect(find.byType(CtNinePatchButton), findsOneWidget);
      expect(find.text('panel'), findsOneWidget);
      expect(find.text('button'), findsOneWidget);
    },
  );

  test(
    'negative: CtPanel and CtNinePatchButton sources omit destTileSize',
    () {
      final String libWidgets = p.join('lib', 'widgets');
      final List<String> sources = [
        p.join(libWidgets, 'ct_panel.dart'),
        p.join(libWidgets, 'ct_nine_patch_button.dart'),
      ];
      for (final String relative in sources) {
        final String contents = File(relative).readAsStringSync();
        expect(
          contents.contains('destTileSize'),
          isFalse,
          reason: '$relative must not retain destTileSize (Refs #4035)',
        );
      }
    },
  );
}
