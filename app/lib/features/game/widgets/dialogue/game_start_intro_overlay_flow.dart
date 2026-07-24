import 'package:colonizethis_app/config/app_assets.dart';
import 'package:colonizethis_app/package_logger.dart';
import 'package:colonizethis_app_fixtures/runtime/app_perf_trace.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jenny/jenny.dart';

import 'ct_dialogue_view.dart';
import 'game_start_intro_overlay.dart';
import 'yarn_dialogue_bootstrap.dart';

/// Host factory for `repo.dialogue_blocking_combined_step` (Refs #3878, #4013).
CtDialogueView createGameStartIntroDialogueView(CtLogger log) =>
    CtDialogueView(logger: log);

/// Yarn node id for the game-start intro dialogue asset.
const String kGameStartIntroNode = 'game_start_intro';

mixin GameStartIntroOverlayFlow on State<GameStartIntroOverlay> {
  CtDialogueView? get introView;
  set introView(CtDialogueView? value);
  DialogueRunner? get introRunner;
  set introRunner(DialogueRunner? value);
  Object? get introLoadError;
  set introLoadError(Object? value);
  bool get introDialogueFinished;
  set introDialogueFinished(bool value);
  bool get introLoggedFirstLine;
  set introLoggedFirstLine(bool value);

  Future<void> loadAndRunIntro() async {
    final log = widget.logger ?? packageLogger('dialogue');
    try {
      final bundle = widget.assetBundle ?? rootBundle;
      ctAppPerfInstant('intro.asset_load.begin');
      log.i('game_intro asset_load begin asset=$kDialogueGameIntroAsset');
      final text = await bundle.loadString(kDialogueGameIntroAsset);
      ctAppPerfInstant('intro.asset_load.end');
      log.i('game_intro asset_load end chars=${text.length}');
      final session = await loadYarnDialogueSession(
        bundle: bundle,
        assetPath: kDialogueGameIntroAsset,
        yarnSource: text,
        logger: log,
        createView: createGameStartIntroDialogueView,
        requiredNodes: const [kGameStartIntroNode],
      );
      final view = session.view;
      final runner = session.runner;
      view.onStateChanged = (line, choice) {
        if (!introLoggedFirstLine && line != null) {
          introLoggedFirstLine = true;
          ctAppPerfInstant('intro.first_line');
          log.i('game_intro first_line_shown');
        }
        if (mounted) setState(() {});
      };
      if (!mounted) return;
      setState(() {
        introView = view;
        introRunner = runner;
      });
      ctAppPerfInstant('intro.dialogue_begin');
      log.i('game_intro dialogue_begin node=$kGameStartIntroNode');
      await runner.startDialogue(kGameStartIntroNode);
      if (!mounted) return;
      setState(() => introDialogueFinished = true);
      widget.onDismissed();
    } catch (e, st) {
      log.e(
        'ui:dialogue: failed to load or run intro',
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        setState(() => introLoadError = e);
      }
    }
  }
}
