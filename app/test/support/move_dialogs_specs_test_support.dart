// Shared opener for move_dialogs_specs_part*_test (Refs #4013, #4035).
import 'package:flutter/material.dart';

import 'app_shell_harness.dart';

/// Scaffold + "open" button; [builder] receives ambient [BuildContext].
Widget moveDialogsSpecsFrameWithOpener(
  VoidCallback Function(BuildContext) builder,
) {
  return buildAppShell(
    child: Scaffold(
      body: Builder(
        builder: (context) =>
            TextButton(onPressed: builder(context), child: const Text('open')),
      ),
    ),
  );
}
