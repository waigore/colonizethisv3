import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:jenny/jenny.dart';
import 'package:logger/logger.dart';

import '../../../../widgets/ct_dialog_shell.dart';
import '../../../../widgets/ct_nine_patch_button.dart';
import 'ct_dialogue_view.dart';

/// Modal overlay that shows the game-start intro dialogue (archaic language) and
/// blocks until the player dismisses it. SPEC/ai/dialogue-management.md § First dialogue emission point.
class GameStartIntroOverlay extends StatefulWidget {
  const GameStartIntroOverlay({
    super.key,
    required this.onDismissed,
    required this.child,
    this.logger,
    /// When set (e.g. in tests), used to load the Yarn asset instead of [rootBundle].
    this.assetBundle,
  });

  final VoidCallback onDismissed;
  final Widget child;
  final Logger? logger;
  final AssetBundle? assetBundle;

  @override
  State<GameStartIntroOverlay> createState() => _GameStartIntroOverlayState();
}

class _GameStartIntroOverlayState extends State<GameStartIntroOverlay> {
  static const String _kIntroAsset = 'assets/dialogue/game_intro.yarn';
  static const String _kIntroNode = 'game_start_intro';

  CtDialogueView? _view;
  DialogueRunner? _runner;
  Object? _loadError;
  bool _dialogueFinished = false;

  @override
  void initState() {
    super.initState();
    _loadAndRun();
  }

  Future<void> _loadAndRun() async {
    final log = widget.logger ?? Logger();
    try {
      final bundle = widget.assetBundle ?? rootBundle;
      final text = await bundle.loadString(_kIntroAsset);
      final project = YarnProject();
      project.parse(text);
      if (!project.nodes.containsKey(_kIntroNode)) {
        throw StateError('Intro node "$_kIntroNode" not found in $_kIntroAsset');
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
      await runner.startDialogue(_kIntroNode);
      if (!mounted) return;
      setState(() => _dialogueFinished = true);
      widget.onDismissed();
    } catch (e, st) {
      log.e('ui:dialogue: failed to load or run intro', error: e, stackTrace: st);
      if (mounted) {
        setState(() => _loadError = e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) {
      return Stack(
        children: [
          widget.child,
          Material(
            color: Colors.black54,
            child: Center(
              child: CtDialogShell(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Could not load intro dialogue: $_loadError'),
                      const SizedBox(height: 16),
                      CtNinePatchButton(
                        onPressed: () {
                          setState(() => _loadError = null);
                          widget.onDismissed();
                        },
                        child: const Text('Continue'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (_dialogueFinished || _view == null || _runner == null) {
      return widget.child;
    }

    final line = _view!.currentLine;
    final choice = _view!.currentChoice;

    return Stack(
      children: [
        widget.child,
        Material(
          color: Colors.black54,
          child: Center(
            child: CtDialogShell(
              maxWidth: 520,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (line != null) ...[
                      Text(
                        line.text,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: CtNinePatchButton(
                          onPressed: () => _view!.advanceLine(),
                          child: const Text('Continue'),
                        ),
                      ),
                    ] else if (choice != null) ...[
                      ...choice.options.asMap().entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: CtNinePatchButton(
                            onPressed: () => _view!.selectOption(entry.key),
                            child: Text(entry.value.text),
                          ),
                        ),
                      ),
                    ] else
                      const Center(child: CircularProgressIndicator()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
