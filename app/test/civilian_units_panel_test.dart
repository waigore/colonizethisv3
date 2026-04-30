// Tests for CivilianUnitsPanel. SPEC/ui/civilian-units-panel.md.

import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/core/services/app_event_handler_scope.dart';
import 'package:colonizethis_app/features/game/widgets/civilian_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_entity_action_row.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_panel_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';
import 'package:colonizethis_app/widgets/resource_icon.dart';

part 'civilian_units_panel_test_body_part.g.dart';

class _EventHandlingWrapper extends StatefulWidget {
  const _EventHandlingWrapper({
    required this.bus,
    required this.child,
    required this.navigatorKey,
  });

  final AppEventBus bus;
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<_EventHandlingWrapper> createState() => _EventHandlingWrapperState();
}

class _EventHandlingWrapperState extends State<_EventHandlingWrapper> {
  StreamSubscription? _confirmSub;
  StreamSubscription? _closeSub;

  @override
  void initState() {
    super.initState();
    _closeSub = widget.bus.on<ClosePanelEvent>().listen((_) {
      widget.navigatorKey.currentState?.maybePop();
    });
    _confirmSub = widget.bus.on<ConfirmDialogEvent>().listen((event) async {
      final nav = widget.navigatorKey.currentState;
      if (nav == null) return;
      final result = await showDialog<bool>(
        context: nav.context,
        builder: (ctx) => AlertDialog(
          title: Text(event.title),
          content: Text(event.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(event.cancelLabel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(event.confirmLabel),
            ),
          ],
        ),
      );
      event.result(result ?? false);
    });
  }

  @override
  void dispose() {
    _confirmSub?.cancel();
    _closeSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}


void main() {
  _defineTests();
}
