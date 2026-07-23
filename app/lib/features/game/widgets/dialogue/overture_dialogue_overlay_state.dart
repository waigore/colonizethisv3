import 'package:flutter/material.dart';

import 'ct_dialogue_view.dart';
import 'overture_dialogue_overlay_build.dart';
import 'overture_dialogue_overlay_flow.dart';
import 'overture_dialogue_overlay_widget.dart';

/// Stateful host for [OvertureDialogueOverlay] (de-parted wave-9 cluster, Refs #4117).
class OvertureDialogueOverlayState extends State<OvertureDialogueOverlay>
    with OvertureDialogueOverlayFlow, OvertureDialogueOverlayBuild {
  @override
  bool overtureIntroDone = false;
  @override
  CtDialogueView? overtureView;
  @override
  Object? overtureLoadError;

  @override
  late List<bool?> accepted;

  @override
  void initState() {
    super.initState();
    accepted = List<bool?>.filled(widget.pendingOvertures.length, null);
    if (widget.skipIntroForTest) {
      overtureIntroDone = true;
    } else {
      loadAndRunOvertureIntro();
    }
  }

  @override
  void updateOvertureDecision(int index, bool? next) {
    setState(() => accepted[index] = next);
  }

  @override
  Widget build(BuildContext context) => buildOvertureDialogueOverlay(context);
}
