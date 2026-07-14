// Shared helpers for dialogue_overlays_specs_part*_test (Refs #4013).
// Pins SPEC/ui ct-dialogue-view + blocking dialogue overlay contracts.

import 'dart:io' show File;

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/dialogue/game_start_intro_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Short settle loop used by blocking-overlay widget pins.
Future<void> pumpDialogueOverlaysUntilSettled(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// Reads a library file plus any `part` files it declares (Dart 3 library
/// unit). Used by static source-contract tests after `part` extractions.
String dialogueOverlaysLibraryUnitSource(String libraryRelPath) {
  final libraryFile = File(libraryRelPath);
  final librarySource = libraryFile.readAsStringSync();
  final dir = libraryFile.parent.path;
  final partRegex = RegExp(r"^\s*part\s+'([^']+)';", multiLine: true);
  final partSources = partRegex
      .allMatches(librarySource)
      .map((m) => File('$dir/${m.group(1)!}').readAsStringSync())
      .join('\n');
  return '$librarySource\n$partSources';
}

/// Wraps [GameStartIntroOverlay] under colonial theme for SPEC pins.
Widget wrapGameStartIntroOverlay({
  required AssetBundle bundle,
  required VoidCallback onDismissed,
  Key? childKey,
}) {
  return MaterialApp(
    theme: AppThemes.colonial,
    locale: const Locale('en'),
    supportedLocales: const [Locale('en')],
    localizationsDelegates: const [
      // Reuse Material delegates so appL10n resolves english strings.
    ],
    home: Scaffold(
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
