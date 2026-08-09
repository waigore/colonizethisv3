import 'package:flutter/material.dart';
import 'package:jenny/jenny.dart';

import 'ct_dialogue_view.dart';
import 'game_start_intro_overlay.dart';
import 'game_start_intro_overlay_build.dart';
import 'game_start_intro_overlay_flow.dart';

class GameStartIntroOverlayState extends State<GameStartIntroOverlay>
    with GameStartIntroOverlayFlow, GameStartIntroOverlayBuild {
  @override
  CtDialogueView? introView;
  @override
  DialogueRunner? introRunner;
  @override
  Object? introLoadError;
  @override
  bool introDialogueFinished = false;
  @override
  bool introLoggedFirstLine = false;

  @override
  void initState() {
    super.initState();
    loadAndRunIntro();
  }

  @override
  Widget build(BuildContext context) => buildIntroOverlay(context);
}
