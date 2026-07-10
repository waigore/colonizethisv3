part of 'tribe_first_contact_overlay.dart';

extension _TribeFirstContactOverlayFlow on _TribeFirstContactOverlayState {
  static const String kNode = 'tribe_first_contact';

  Future<void> loadAndRunTribeFirstContact() async {
    final log = widget.logger ?? packageLogger('dialogue');
    try {
      final bundle = widget.assetBundle ?? rootBundle;
      final text = await bundle.loadString(kDialogueTribeFirstContactAsset);
      final project = YarnProject();
      // Jenny resolves `{$tribeName}` / `{$capitalName}` interpolation at PARSE
      // time and stores variables under their `$`-prefixed name, so the bindings
      // must use the `$` prefix AND be set before `parse` — otherwise parsing
      // throws `NameError: variable $tribeName is not defined` and blocks the
      // game (#3463). StringVariable reads storage at runtime, so these values
      // are reflected when the line renders.
      project.variables.setVariable(r'$tribeName', widget.tribeName);
      project.variables.setVariable(r'$capitalName', widget.capitalName);
      project.parse(text);
      if (!project.nodes.containsKey(kNode)) {
        throw StateError(
          'Tribe first-contact node "$kNode" not found in '
          '$kDialogueTribeFirstContactAsset',
        );
      }

      final view = CtDialogueView(logger: log);
      final runner = DialogueRunner(
        yarnProject: project,
        dialogueViews: [view],
      );
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
