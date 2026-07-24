import 'package:colonizethis_app/config/app_assets.dart';
import 'package:colonizethis_app/package_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jenny/jenny.dart';

import 'ct_dialogue_view.dart';
import 'tribe_first_contact_overlay.dart';
import 'yarn_dialogue_bootstrap.dart';

/// Yarn node id for the tribe-first-contact herald asset.
const String kTribeFirstContactNode = 'tribe_first_contact';

mixin TribeFirstContactOverlayFlow on State<TribeFirstContactOverlay> {
  CtDialogueView? get tribeContactView;
  set tribeContactView(CtDialogueView? value);
  DialogueRunner? get tribeContactRunner;
  set tribeContactRunner(DialogueRunner? value);
  Object? get tribeContactLoadError;
  set tribeContactLoadError(Object? value);
  bool get tribeContactDialogueFinished;
  set tribeContactDialogueFinished(bool value);

  Future<void> loadAndRunTribeFirstContact() async {
    final log = widget.logger ?? packageLogger('dialogue');
    try {
      final bundle = widget.assetBundle ?? rootBundle;
      // Seed `$`-prefixed vars before parse (Jenny interpolate, Refs #3463).
      final session = await loadYarnDialogueSession(
        bundle: bundle,
        assetPath: kDialogueTribeFirstContactAsset,
        logger: log,
        createView: createTribeFirstContactDialogueView,
        beforeParse: (project) {
          project.variables.setVariable(r'$tribeName', widget.tribeName);
          project.variables.setVariable(r'$capitalName', widget.capitalName);
        },
        requiredNodes: const [kTribeFirstContactNode],
      );
      final view = session.view;
      final runner = session.runner;
      view.onStateChanged = (line, choice) {
        if (mounted) setState(() {});
      };
      if (!mounted) return;
      setState(() {
        tribeContactView = view;
        tribeContactRunner = runner;
      });
      await runner.startDialogue(kTribeFirstContactNode);
      if (!mounted) return;
      setState(() => tribeContactDialogueFinished = true);
      widget.onDismissed();
    } catch (e, st) {
      log.e(
        'ui:dialogue: failed to load or run tribe first-contact herald',
        error: e,
        stackTrace: st,
      );
      if (mounted) setState(() => tribeContactLoadError = e);
    }
  }
}
