// Shared YarnAsset → YarnProject → DialogueRunner bootstrap for dialogue
// overlay flows. Preserves Jenny `$`-variable seed-before-parse timing
// (Refs #3463). Refs #4013.

import 'package:colonizethis_app/package_logger.dart';
import 'package:flutter/services.dart';
import 'package:jenny/jenny.dart';

import 'ct_dialogue_view.dart';

/// Result of loading a Yarn asset and constructing a [DialogueRunner].
class YarnDialogueSession {
  const YarnDialogueSession({
    required this.project,
    required this.view,
    required this.runner,
  });

  final YarnProject project;
  final CtDialogueView view;
  final DialogueRunner runner;
}

/// Loads [assetPath] from [bundle], optionally seeds Jenny variables via
/// [beforeParse] (must run before `parse` for `$`-prefixed interpolate keys),
/// parses the Yarn, asserts [requiredNodes] exist, then builds a
/// [CtDialogueView] + [DialogueRunner].
Future<YarnDialogueSession> loadYarnDialogueSession({
  required AssetBundle bundle,
  required String assetPath,
  required CtLogger logger,
  String? yarnSource,
  void Function(YarnProject project)? beforeParse,
  CtDialogueView Function(CtLogger logger)? createView,
  Iterable<String> requiredNodes = const [],
}) async {
  final text = yarnSource ?? await bundle.loadString(assetPath);
  final project = YarnProject();
  beforeParse?.call(project);
  project.parse(text);
  for (final node in requiredNodes) {
    if (!project.nodes.containsKey(node)) {
      throw StateError('Yarn node "$node" not found in $assetPath');
    }
  }
  final view = (createView ?? (log) => CtDialogueView(logger: log))(logger);
  final runner = DialogueRunner(
    yarnProject: project,
    dialogueViews: [view],
  );
  return YarnDialogueSession(project: project, view: view, runner: runner);
}
