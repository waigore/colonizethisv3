// Shared helpers for dialogue_overlays_specs_part*_test (Refs #4013 / #4117 slice F).
// Pins SPEC/ui ct-dialogue-view + blocking dialogue overlay contracts.

import 'dart:io' show File;

import 'package:colonizethis_app/features/game/widgets/dialogue/game_start_intro_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

/// Short settle loop used by blocking-overlay widget pins.
Future<void> pumpDialogueOverlaysUntilSettled(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// Reads a library file plus any `part` files and same-directory sibling
/// libraries it imports (de-parted clusters). Used by static source-contract
/// tests after `part` / explicit-import extractions (Refs #4117).
String dialogueOverlaysLibraryUnitSource(String libraryRelPath) {
  final buffer = StringBuffer();
  final visited = <String>{};

  void appendFile(String path) {
    final canonical = File(path).absolute.path;
    if (visited.contains(canonical)) {
      return;
    }
    final file = File(path);
    if (!file.existsSync()) {
      return;
    }
    visited.add(canonical);
    final source = file.readAsStringSync();
    buffer.writeln(source);

    final dir = file.parent.path;
    final partRegex = RegExp(r"^\s*part\s+'([^']+)';", multiLine: true);
    for (final match in partRegex.allMatches(source)) {
      appendFile('$dir/${match.group(1)!}');
    }

    final importRegex = RegExp(r"^\s*import\s+'([^']+)';", multiLine: true);
    for (final match in importRegex.allMatches(source)) {
      final importPath = match.group(1)!;
      if (importPath.contains('/')) {
        continue;
      }
      appendFile('$dir/$importPath');
    }
  }

  appendFile(libraryRelPath);
  return buffer.toString();
}

/// Wraps [GameStartIntroOverlay] under editorial [buildAppShell] for SPEC pins
/// (Refs #4035 — no inline MaterialApp).
Widget wrapGameStartIntroOverlay({
  required AssetBundle bundle,
  required VoidCallback onDismissed,
  Key? childKey,
}) {
  return buildAppShell(
    locale: const Locale('en'),
    supportedLocales: const [Locale('en')],
    child: Scaffold(
      body: GameStartIntroOverlay(
        onDismissed: onDismissed,
        assetBundle: bundle,
        child: SizedBox.expand(
          key: childKey,
          child: const Center(child: Text('child-content')),
        ),
      ),
    ),
  );
}
