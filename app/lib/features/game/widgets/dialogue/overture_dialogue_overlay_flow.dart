// Yarn intro orchestration for [OvertureDialogueOverlay].
// Split from `overture_dialogue_overlay.dart` to keep the overlay host
// under the repo file-size target (Refs #3878).

import 'package:colonizethis_app/config/app_assets.dart';
import 'package:colonizethis_app/package_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ct_dialogue_view.dart';
import 'overture_dialogue_overlay.dart';
import 'yarn_dialogue_bootstrap.dart';

/// Host factory for `repo.dialogue_blocking_combined_step` (Refs #3878).
CtDialogueView createOvertureDialogueView(CtLogger log) =>
    CtDialogueView(logger: log);

mixin OvertureDialogueOverlayFlow on State<OvertureDialogueOverlay> {
  bool get overtureIntroDone;
  set overtureIntroDone(bool value);
  CtDialogueView? get overtureView;
  set overtureView(CtDialogueView? value);
  Object? get overtureLoadError;
  set overtureLoadError(Object? value);

  Future<void> loadAndRunOvertureIntro() async {
    final log = widget.logger ?? packageLogger('dialogue');
    try {
      final bundle = widget.assetBundle ?? rootBundle;
      final session = await loadYarnDialogueSession(
        bundle: bundle,
        assetPath: kDialogueOvertureAsset,
        logger: log,
        createView: createOvertureDialogueView,
        requiredNodes: const [_kOvertureNode],
      );
      final view = session.view;
      final runner = session.runner;
      view.onStateChanged = (line, choice) {
        if (mounted) setState(() {});
      };
      if (!mounted) return;
      setState(() {
        overtureView = view;
      });
      await runner.startDialogue(_kOvertureNode);
      if (!mounted) return;
      setState(() => overtureIntroDone = true);
    } catch (e, st) {
      log.e(
        'ui:dialogue: failed to load overture intro',
        error: e,
        stackTrace: st,
      );
      if (mounted) setState(() => overtureLoadError = e);
    }
  }
}

const String _kOvertureNode = 'DialoguePoint/overture_target_response';
