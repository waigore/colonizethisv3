import 'package:flutter/material.dart';
import 'package:jenny/jenny.dart';

import 'ct_dialogue_view.dart';
import 'tribe_first_contact_overlay.dart';
import 'tribe_first_contact_overlay_build.dart';
import 'tribe_first_contact_overlay_flow.dart';

class TribeFirstContactOverlayState extends State<TribeFirstContactOverlay>
    with TribeFirstContactOverlayFlow, TribeFirstContactOverlayBuild {
  @override
  CtDialogueView? tribeContactView;
  @override
  DialogueRunner? tribeContactRunner;
  @override
  Object? tribeContactLoadError;
  @override
  bool tribeContactDialogueFinished = false;

  @override
  void initState() {
    super.initState();
    loadAndRunTribeFirstContact();
  }

  @override
  Widget build(BuildContext context) => buildTribeFirstContactOverlay(context);
}
