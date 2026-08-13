// Shared next-turn label host/controller for
// `e2e_wait_for_next_turn_label_advance_test.dart` (#4344 Slice C densify).
library;

import 'dart:async';

import 'package:colonizethis_app/features/game/flame/overlays/turn_resolution_processing_dialog.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Host that mounts a key-tagged next-turn label (and an optional
/// [TurnResolutionProcessingDialog]) and exposes a fake-async `Timer`-driven
/// hook for tests to flip the label or dismiss the dialog while the
/// helper's `tester.pump` loop is running.
///
/// `Timer` callbacks scheduled in [State.initState] fire when `tester.pump`
/// advances fake-time past the registered duration, so the helper observes
/// the flip on a later polling iteration without the test needing to call
/// `tester.pump` itself (which would deadlock against the helper's guarded
/// pump).
class NextTurnLabelHost extends StatefulWidget {
  const NextTurnLabelHost({
    super.key,
    required this.controller,
    this.flipAfter,
    this.flipToLabel,
    this.flipToShowDialog,
  });

  final NextTurnLabelController controller;

  /// Fake-async delay before the host flips the controller, or `null` to
  /// leave the controller untouched (no scheduled flip).
  final Duration? flipAfter;

  /// New label to apply when [flipAfter] elapses, or `null` to leave the
  /// label unchanged.
  final String? flipToLabel;

  /// New processing-dialog visibility to apply when [flipAfter] elapses,
  /// or `null` to leave the visibility unchanged.
  final bool? flipToShowDialog;

  @override
  State<NextTurnLabelHost> createState() => _NextTurnLabelHostState();
}

class _NextTurnLabelHostState extends State<NextTurnLabelHost> {
  Timer? _flipTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    final after = widget.flipAfter;
    if (after != null) {
      _flipTimer = Timer(after, _applyFlip);
    }
  }

  void _applyFlip() {
    final newLabel = widget.flipToLabel;
    if (newLabel != null) {
      widget.controller.label = newLabel;
    }
    final newDialog = widget.flipToShowDialog;
    if (newDialog != null) {
      widget.controller.showProcessingDialog = newDialog;
    }
  }

  @override
  void dispose() {
    _flipTimer?.cancel();
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final showDialog = widget.controller.showProcessingDialog;
    final label = widget.controller.label;
    return Stack(
      children: [
        Center(
          child: TextButton(
            key: kGameMapNextTurnButtonKey,
            onPressed: () {},
            child: Text(label),
          ),
        ),
        if (showDialog)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x88000000),
              child: Center(
                child: TurnResolutionProcessingDialog(
                  phaseText: 'Validating orders...',
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class NextTurnLabelController extends ChangeNotifier {
  NextTurnLabelController({
    required String initialLabel,
    bool initialShowProcessingDialog = false,
  }) : _label = initialLabel,
       _showProcessingDialog = initialShowProcessingDialog;

  String _label;
  bool _showProcessingDialog;

  String get label => _label;

  set label(String value) {
    if (_label == value) {
      return;
    }
    _label = value;
    notifyListeners();
  }

  bool get showProcessingDialog => _showProcessingDialog;

  set showProcessingDialog(bool value) {
    if (_showProcessingDialog == value) {
      return;
    }
    _showProcessingDialog = value;
    notifyListeners();
  }
}

Future<void> pumpNextTurnLabelHost(
  WidgetTester tester,
  NextTurnLabelController controller, {
  Duration? flipAfter,
  String? flipToLabel,
  bool? flipToShowDialog,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: NextTurnLabelHost(
          controller: controller,
          flipAfter: flipAfter,
          flipToLabel: flipToLabel,
          flipToShowDialog: flipToShowDialog,
        ),
      ),
    ),
  );
}
