// Next-turn **advance** host: keyed next-turn button plus optional
// `common_yes` confirm chip (#4598 Slice B). Distinct from
// `next_turn_label_harness.dart`, which mounts a processing dialog rather
// than the confirm chip used by `e2eAdvanceOneHumanTurn`.
library;

import 'dart:async';

import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_widget_pump_harness.dart';

/// Stateful host that mounts a key-tagged next-turn button plus an optional
/// `common_yes` confirm chip. A fake-async [Timer] scheduled in
/// [State.initState] can flip the label or dialog visibility after a delay.
class NextTurnAdvanceHost extends StatefulWidget {
  const NextTurnAdvanceHost({
    super.key,
    required this.controller,
    this.flipAfter,
    this.flipToLabel,
    this.flipToShowConfirm,
  });

  final NextTurnAdvanceController controller;
  final Duration? flipAfter;
  final String? flipToLabel;
  final bool? flipToShowConfirm;

  @override
  State<NextTurnAdvanceHost> createState() => _NextTurnAdvanceHostState();
}

class _NextTurnAdvanceHostState extends State<NextTurnAdvanceHost> {
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
    final newShow = widget.flipToShowConfirm;
    if (newShow != null) {
      widget.controller.showConfirm = newShow;
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
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      children: [
        Center(
          child: TextButton(
            key: kGameMapNextTurnButtonKey,
            onPressed: widget.controller.onNextTurnTapped,
            child: Text(widget.controller.label),
          ),
        ),
        if (widget.controller.showConfirm)
          Positioned(
            top: 32,
            left: 32,
            child: Material(
              child: TextButton(
                onPressed: widget.controller.onConfirmTapped,
                child: Text(l10n.common_yes),
              ),
            ),
          ),
      ],
    );
  }
}

class NextTurnAdvanceController extends ChangeNotifier {
  NextTurnAdvanceController({
    required String initialLabel,
    bool initialShowConfirm = false,
    this.onNextTurnTapped,
    this.onConfirmTapped,
  }) : _label = initialLabel,
       _showConfirm = initialShowConfirm;

  String _label;
  bool _showConfirm;

  final VoidCallback? onNextTurnTapped;
  final VoidCallback? onConfirmTapped;

  String get label => _label;
  set label(String value) {
    if (_label == value) return;
    _label = value;
    notifyListeners();
  }

  bool get showConfirm => _showConfirm;
  set showConfirm(bool value) {
    if (_showConfirm == value) return;
    _showConfirm = value;
    notifyListeners();
  }
}

Future<void> pumpNextTurnAdvanceHost(
  WidgetTester tester,
  NextTurnAdvanceController controller, {
  Duration? flipAfter,
  String? flipToLabel,
  bool? flipToShowConfirm,
}) {
  return pumpE2eLocalizedScaffold(
    tester,
    NextTurnAdvanceHost(
      controller: controller,
      flipAfter: flipAfter,
      flipToLabel: flipToLabel,
      flipToShowConfirm: flipToShowConfirm,
    ),
  );
}
