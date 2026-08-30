// Civilian work-menu label host for `e2eAwaitCivilianWorkMenuMounted` pins
// (#4598 Slice B).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_widget_pump_harness.dart';

class CivilianWorkMenuHost extends StatefulWidget {
  const CivilianWorkMenuHost({
    super.key,
    required this.controller,
    this.mountAfter,
    this.labelToMount,
  });

  final CivilianWorkMenuController controller;
  final Duration? mountAfter;
  final String? labelToMount;

  @override
  State<CivilianWorkMenuHost> createState() => _CivilianWorkMenuHostState();
}

class _CivilianWorkMenuHostState extends State<CivilianWorkMenuHost> {
  Timer? _mountTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    final after = widget.mountAfter;
    final label = widget.labelToMount;
    if (after != null && label != null) {
      _mountTimer = Timer(after, () {
        widget.controller.mountedLabel = label;
      });
    }
  }

  @override
  void dispose() {
    _mountTimer?.cancel();
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.controller.mountedLabel;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[if (label != null) Text(label)],
    );
  }
}

class CivilianWorkMenuController extends ChangeNotifier {
  CivilianWorkMenuController({String? initialLabel})
    : _mountedLabel = initialLabel;

  String? _mountedLabel;

  String? get mountedLabel => _mountedLabel;

  set mountedLabel(String? value) {
    if (_mountedLabel == value) return;
    _mountedLabel = value;
    notifyListeners();
  }
}

Future<void> pumpCivilianWorkMenuHost(
  WidgetTester tester,
  CivilianWorkMenuController controller, {
  Duration? mountAfter,
  String? labelToMount,
}) {
  return pumpE2eScaffold(
    tester,
    Center(
      child: CivilianWorkMenuHost(
        controller: controller,
        mountAfter: mountAfter,
        labelToMount: labelToMount,
      ),
    ),
  );
}
