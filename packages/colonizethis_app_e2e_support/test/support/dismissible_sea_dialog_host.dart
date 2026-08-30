// Shared sea-radio move-dialog host for `e2e_try_naval_move_segment_test.dart`
// (Refs #4598 leftover host SoT). Pin suites import this instead of declaring
// `_DismissibleSeaDialog` locally. Keep deprecated RadioListTile
// groupValue/onChanged on the fixture, not RadioGroup.
library;

// ignore_for_file: deprecated_member_use

import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_contract.dart';
import 'package:flutter/material.dart';

/// Pin label for a legal sea-zone radio in the fleet-move dialog.
const String kE2eDismissibleSeaDialogPinLabel = 'sea zone 1';

/// AlertDialog whose confirm action pops the route after a sea radio is shown.
class DismissibleSeaDialog extends StatefulWidget {
  const DismissibleSeaDialog({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  State<DismissibleSeaDialog> createState() => DismissibleSeaDialogState();
}

class DismissibleSeaDialogState extends State<DismissibleSeaDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SingleChildScrollView(
        key: kCtE2EMoveFleetDialogScrollRootKey,
        child: RadioListTile<int>(
          title: const Text(kE2eDismissibleSeaDialogPinLabel),
          value: 0,
          groupValue: 0,
          onChanged: (_) {},
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.l10n.common_confirm),
        ),
      ],
    );
  }
}
