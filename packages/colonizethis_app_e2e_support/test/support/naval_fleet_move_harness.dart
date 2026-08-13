// Shared naval fleet-row Move fixtures for the naval-move-family suites
// (#4344 Slice C densify): `e2e_attempt_first_fleet_move_or_cancel_test.dart`,
// `e2e_tap_move_on_first_non_home_fleet_test.dart`, and
// `e2e_try_naval_move_segment_test.dart` previously each declared their own
// `_MoveButton` variant that mirrored the production fleet-row Move action
// (`fleet_expansion_tile.dart`) with slightly different constructor shapes.
// This harness unifies them behind one [FleetMoveButton] plus the shared
// `fleetMoveTile` / `navalPanelRoot` / `wrapNavalScrollBody` scaffolding.
library;

import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:flutter/material.dart';

/// Mounts a Move control that opens a dialog when tapped, mirroring the
/// production fleet-row Move button surface (`fleet_expansion_tile.dart`).
///
/// [buttonKey] carries the production [kCtE2EFleetMoveActionKey] at most
/// call sites so keyed-finder helpers can locate the control even when
/// [iconOnly] suppresses the `Text('Move')` label — production collapses
/// the dense naval action cluster to icon-only at narrow test-host
/// viewports (Refs #2336). Pass `null` to mirror an unkeyed control (for
/// example a home-fleet Move button the helper under test must not tap).
class FleetMoveButton extends StatelessWidget {
  const FleetMoveButton({
    super.key,
    this.onPressedSpy,
    this.dialogBuilder,
    this.buttonKey,
    this.iconOnly = false,
  });

  final void Function()? onPressedSpy;
  final WidgetBuilder? dialogBuilder;
  final Key? buttonKey;
  final bool iconOnly;

  static Widget _defaultDialog(BuildContext _) =>
      const AlertDialog(content: Text('Move dialog'));

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        void onPressed() {
          onPressedSpy?.call();
          showDialog<void>(
            context: context,
            builder: dialogBuilder ?? _defaultDialog,
          );
        }

        if (iconOnly) {
          return IconButton(
            key: buttonKey,
            tooltip: 'Move',
            icon: const Icon(Icons.route),
            onPressed: onPressed,
          );
        }
        return TextButton(
          key: buttonKey,
          onPressed: onPressed,
          child: const Text('Move'),
        );
      },
    );
  }
}

/// Builds a fleet [ExpansionTile] with a `title`, optional `subtitle` line,
/// and a [FleetMoveButton] as the expanded child. [buttonKey] defaults to
/// the production [kCtE2EFleetMoveActionKey] so keyed-finder helpers
/// resolve non-home Move controls.
ExpansionTile fleetMoveTile({
  required String title,
  String? subtitle,
  bool initiallyExpanded = true,
  bool iconOnly = false,
  void Function()? onMovePressed,
  WidgetBuilder? dialogBuilder,
  Key? buttonKey = kCtE2EFleetMoveActionKey,
}) {
  return ExpansionTile(
    title: Text(title),
    subtitle: subtitle == null ? null : Text(subtitle),
    initiallyExpanded: initiallyExpanded,
    children: [
      FleetMoveButton(
        onPressedSpy: onMovePressed,
        iconOnly: iconOnly,
        dialogBuilder: dialogBuilder,
        buttonKey: buttonKey,
      ),
    ],
  );
}

/// Wraps panel children under [kCtE2ENavalPanelRootKey] so `find.byKey`
/// helpers resolve the naval panel root.
Widget navalPanelRoot({required List<Widget> children}) => KeyedSubtree(
  key: kCtE2ENavalPanelRootKey,
  child: Column(children: children),
);

/// `MaterialApp` → `Scaffold` → scrollable body — common naval-suite pump
/// wrapper (keeps many stacked fleet tiles overflow-safe).
Widget wrapNavalScrollBody(Widget body) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: body)),
);
