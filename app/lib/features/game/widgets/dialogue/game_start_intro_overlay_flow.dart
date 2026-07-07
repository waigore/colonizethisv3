part of 'game_start_intro_overlay.dart';

extension _GameStartIntroOverlayFlow on _GameStartIntroOverlayState {
  static const String kIntroNode = 'game_start_intro';

  Future<void> loadAndRunIntro() async {
    final log = widget.logger ?? packageLogger('dialogue');
    try {
      final bundle = widget.assetBundle ?? rootBundle;
      ctAppPerfInstant('intro.asset_load.begin');
      log.i('game_intro asset_load begin asset=$kDialogueGameIntroAsset');
      final text = await bundle.loadString(kDialogueGameIntroAsset);
      ctAppPerfInstant('intro.asset_load.end');
      log.i('game_intro asset_load end chars=${text.length}');
      final project = YarnProject();
      project.parse(text);
      if (!project.nodes.containsKey(kIntroNode)) {
        throw StateError(
          'Intro node "$kIntroNode" not found in $kDialogueGameIntroAsset',
        );
      }
      final view = CtDialogueView(logger: log);
      final runner = DialogueRunner(
        yarnProject: project,
        dialogueViews: [view],
      );
      view.onStateChanged = (line, choice) {
        if (!_loggedFirstLine && line != null) {
          _loggedFirstLine = true;
          ctAppPerfInstant('intro.first_line');
          log.i('game_intro first_line_shown');
        }
        if (mounted) setState(() {});
      };
      if (!mounted) return;
      setState(() {
        _view = view;
        _runner = runner;
      });
      ctAppPerfInstant('intro.dialogue_begin');
      log.i('game_intro dialogue_begin node=$kIntroNode');
      await runner.startDialogue(kIntroNode);
      if (!mounted) return;
      setState(() => _dialogueFinished = true);
      widget.onDismissed();
    } catch (e, st) {
      log.e(
        'ui:dialogue: failed to load or run intro',
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        setState(() => _loadError = e);
      }
    }
  }
}
