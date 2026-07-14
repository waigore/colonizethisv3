// Shared dialog opener frame for move_dialogs_specs_part*_test (Refs #4013).
// Pins SPEC/ui/move-army-dialog.md and SPEC/ui/move-fleet-dialog.md.

import 'package:flutter/material.dart';

/// Pumps a Scaffold with an "open" TextButton whose onPressed is built from
/// the ambient [BuildContext] (for `showDialog` / locate flows).
Widget moveDialogsSpecsFrameWithOpener(
  VoidCallback Function(BuildContext) builder,
) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) =>
            TextButton(onPressed: builder(context), child: const Text('open')),
      ),
    ),
  );
}
