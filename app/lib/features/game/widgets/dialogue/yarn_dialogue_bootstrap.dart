// Shared Yarn → DialogueRunner bootstrap. Seed `$` vars via [beforeParse]
// before parse (Refs #3463). Refs #4013.
import 'package:colonizethis_app/package_logger.dart';
import 'package:flutter/services.dart';
import 'package:jenny/jenny.dart';

import 'ct_dialogue_view.dart';

/// Loaded Yarn project, view, and runner for a dialogue overlay.
class YarnDialogueSession {
  const YarnDialogueSession(this.project, this.view, this.runner);
  final YarnProject project;
  final CtDialogueView view;
  final DialogueRunner runner;
}

/// Loads [assetPath], optional [beforeParse], parse, [requiredNodes], then view+runner.
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
  return YarnDialogueSession(
    project,
    view,
    DialogueRunner(yarnProject: project, dialogueViews: [view]),
  );
}
