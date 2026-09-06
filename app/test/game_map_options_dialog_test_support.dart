import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/widgets/dialogs/game_map_options_dialog.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

Widget gameMapOptionsDialogFrame({
  required MapViewState initialState,
  required ValueChanged<MapViewState> onChanged,
}) {
  return buildAppShell(
    child: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () {
              showDialog<void>(
                context: context,
                barrierColor: EditorialMonoclePalette.dialogScrim,
                builder: (_) => GameMapOptionsDialog(
                  initialState: initialState,
                  onChanged: onChanged,
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

Future<void> openGameMapOptionsDialog(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}
