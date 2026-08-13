library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget wrap(Key panelRootKey, List<Widget> children) => MaterialApp(
  home: Scaffold(
    body: KeyedSubtree(
      key: panelRootKey,
      child: ListView(children: children),
    ),
  ),
);

/// Captures every `debugPrint` line emitted while [body] runs and restores
/// the original printer afterwards (defensive in `finally` so a thrown
/// expectation does not leak the override into later tests).
Future<List<String>> captureDebugPrints(Future<void> Function() body) async {
  final captured = <String>[];
  final original = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    captured.add(message ?? '');
  };
  try {
    await body();
  } finally {
    debugPrint = original;
  }
  return captured;
}


