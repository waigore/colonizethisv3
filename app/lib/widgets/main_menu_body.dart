// Main-menu body layout widgets, split out from `main_menu.dart` to keep the
// host file under the repo-lint non-comment line limit per
// `SPEC/program/dart-file-non-comment-line-size.md`.

import 'package:flutter/material.dart';

import 'main_menu_body_content.dart';
import 'main_menu_constants.dart';

class MainMenuBody extends StatelessWidget {
  const MainMenuBody({
    required this.variant,
    required this.showAfterVictorySubtitle,
    required this.loadGameEnabled,
    required this.resumeGameVisible,
    required this.version,
    required this.onNewGame,
    required this.onResumeGame,
    required this.onLoadGame,
    required this.onSettings,
    required this.onQuit,
    required this.logoBuilder,
    super.key,
  });

  final MainMenuVariant variant;
  final bool showAfterVictorySubtitle;
  final bool loadGameEnabled;
  final bool resumeGameVisible;
  final String version;
  final VoidCallback onNewGame;
  final VoidCallback? onResumeGame;
  final VoidCallback onLoadGame;
  final VoidCallback onSettings;
  final VoidCallback onQuit;
  final Widget Function(BuildContext context) logoBuilder;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool narrow = constraints.maxWidth <= kMainMenuNarrowBreakpoint;
          final EdgeInsets padding = narrow
              ? kMainMenuBodyPaddingNarrow
              : kMainMenuBodyPaddingDefault;
          return Padding(
            key: const Key(kMainMenuBodyPaddingKey),
            padding: padding,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: SingleChildScrollView(
                  child: MainMenuBodyContent(
                    variant: variant,
                    showAfterVictorySubtitle: showAfterVictorySubtitle,
                    loadGameEnabled: loadGameEnabled,
                    resumeGameVisible: resumeGameVisible,
                    narrow: narrow,
                    version: version,
                    onNewGame: onNewGame,
                    onResumeGame: onResumeGame,
                    onLoadGame: onLoadGame,
                    onSettings: onSettings,
                    onQuit: onQuit,
                    logoBuilder: logoBuilder,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
