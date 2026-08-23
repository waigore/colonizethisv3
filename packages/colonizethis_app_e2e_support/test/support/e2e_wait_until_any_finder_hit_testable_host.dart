// Extracted from e2e_wait_until_any_finder_hit_testable_test.dart
// (#4598 headroom).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Host that mounts keyed `TextButton`s when [controller] or a delay says so.
class MountKeysHost extends StatefulWidget {
  const MountKeysHost({
    super.key,
    required this.controller,
    this.mountAfter,
    this.mountKeys = const <Key>[],
  });

  final MountKeysController controller;
  final Duration? mountAfter;
  final List<Key> mountKeys;

  @override
  State<MountKeysHost> createState() => _MountKeysHostState();
}

class _MountKeysHostState extends State<MountKeysHost> {
  Timer? _mountTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    final after = widget.mountAfter;
    if (after != null) {
      _mountTimer = Timer(after, _applyMount);
    }
  }

  void _applyMount() {
    widget.controller.mountedKeys = widget.mountKeys;
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
    final keys = widget.controller.mountedKeys;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final k in keys)
          TextButton(key: k, onPressed: () {}, child: const Text('btn')),
      ],
    );
  }
}

class MountKeysController extends ChangeNotifier {
  MountKeysController({List<Key> initialKeys = const <Key>[]})
    : _mountedKeys = List<Key>.of(initialKeys);

  List<Key> _mountedKeys;

  List<Key> get mountedKeys => _mountedKeys;

  set mountedKeys(List<Key> value) {
    _mountedKeys = List<Key>.of(value);
    notifyListeners();
  }
}

Future<void> pumpMountKeysHost(
  WidgetTester tester,
  MountKeysController controller, {
  Duration? mountAfter,
  List<Key> mountKeys = const <Key>[],
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: MountKeysHost(
            controller: controller,
            mountAfter: mountAfter,
            mountKeys: mountKeys,
          ),
        ),
      ),
    ),
  );
}
