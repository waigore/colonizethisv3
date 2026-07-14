part of 'tribe_first_contact_overlay.dart';

extension _TribeFirstContactOverlayFlow on _TribeFirstContactOverlayState {
  static const String kNode = 'tribe_first_contact';

  Future<void> loadAndRunTribeFirstContact() async {
    final log = widget.logger ?? packageLogger('dialogue');
    try {
      final bundle = widget.assetBundle ?? rootBundle;
      // Seed `$`-prefixed vars before parse (Jenny interpolate, Refs #3463).
      final session = await loadYarnDialogueSession(
        bundle: bundle,
        assetPath: kDialogueTribeFirstContactAsset,
        logger: log,
        createView: _createTribeFirstContactDialogueView,
        beforeParse: (project) {
          project.variables.setVariable(r'$tribeName', widget.tribeName);
          project.variables.setVariable(r'$capitalName', widget.capitalName);
        },
        requiredNodes: const [kNode],
      );
      final view = session.view;
      final runner = session.runner;
      view.onStateChanged = (line, choice) {
        if (mounted) setState(() {});
      };
      if (!mounted) return;
      setState(() {
        _view = view;
        _runner = runner;
      });
      await runner.startDialogue(kNode);
      if (!mounted) return;
      setState(() => _dialogueFinished = true);
      widget.onDismissed();
    } catch (e, st) {
      log.e(
        'ui:dialogue: failed to load or run tribe first-contact herald',
        error: e,
        stackTrace: st,
      );
      if (mounted) setState(() => _loadError = e);
    }
  }
}
