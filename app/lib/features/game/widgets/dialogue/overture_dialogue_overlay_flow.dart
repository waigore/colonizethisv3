// Yarn intro orchestration for [OvertureDialogueOverlay].
// Split from `overture_dialogue_overlay.dart` to keep the overlay host
// under the repo file-size target (Refs #3878).

part of 'overture_dialogue_overlay.dart';

mixin _OvertureDialogueOverlayFlow on State<OvertureDialogueOverlay> {
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
        createView: _createOvertureDialogueView,
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
