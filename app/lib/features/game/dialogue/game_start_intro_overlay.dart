import 'package:colonizethis_app/config/app_assets.dart';
import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/ui_screen_ids.dart';
import 'package:colonizethis_app/package_logger.dart';
import 'package:colonizethis_app/perf/app_perf_trace.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:jenny/jenny.dart';

import '../../../../l10n/l10n.dart';
import '../../../../widgets/ct_brass_divider.dart';
import '../../../../widgets/ct_full_screen_dialogue_shell.dart';
import '../../../../widgets/ct_loading_indicator.dart';
import '../../../../widgets/ct_nine_patch_button.dart';
import '../../../../widgets/ct_spacing.dart';
import 'ct_dialogue_view.dart';

/// Spinner while intro dialogue lines are not yet available.
///
/// Matches the game-initializing progress dialog contract
/// (`NewGameSetupProgressView` / SHEL30001 R32): 48 logical px ring with
/// `--accent` stroke (`EditorialMonoclePalette.accent`). Refs #2867 R28.
class GameStartIntroLoadingIndicator extends StatelessWidget {
  const GameStartIntroLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return CtLoadingIndicator(
      size: 48,
      strokeWidth: 2,
      color: EditorialMonoclePalette.accent,
      center: false,
    );
  }
}

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

  /// SPEC/ui/game-start-intro-overlay.md — [UiScreenIds.gameStartIntroOverlay].
  static const screenId = UiScreenIds.gameStartIntroOverlay;

  final VoidCallback onDismissed;
  final Widget child;
  final CtLogger? logger;
  final AssetBundle? assetBundle;

  @override
  State<GameStartIntroOverlay> createState() => _GameStartIntroOverlayState();
}

class _GameStartIntroOverlayState extends State<GameStartIntroOverlay> {
  static const String _kIntroNode = 'game_start_intro';

  CtDialogueView? _view;
  DialogueRunner? _runner;
  Object? _loadError;
  bool _dialogueFinished = false;
  bool _loggedFirstLine = false;

  @override
  void initState() {
    super.initState();
    _loadAndRun();
  }

  Future<void> _loadAndRun() async {
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
      if (!project.nodes.containsKey(_kIntroNode)) {
        throw StateError(
          'Intro node "$_kIntroNode" not found in $kDialogueGameIntroAsset',
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
      log.i('game_intro dialogue_begin node=$_kIntroNode');
      await runner.startDialogue(_kIntroNode);
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

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final theme = Theme.of(context);
    if (_loadError != null) {
      return CtFullScreenDialogueShell(
        backdrop: widget.child,
        padding: const EdgeInsets.all(CtSpacing.l),
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _IntroTitle(text: l10n.gameStartIntroOverlay_title),
            const SizedBox(height: 12),
            const CtBrassDivider(),
            const SizedBox(height: 14),
            Text(
              l10n.game_intro_loadError('$_loadError'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: EditorialMonoclePalette.accentDim,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.center,
              child: CtNinePatchButton(
                onPressed: () {
                  setState(() => _loadError = null);
                  widget.onDismissed();
                },
                child: Text(l10n.game_intervention_continue),
              ),
            ),
          ],
        ),
      );
    }

    if (_dialogueFinished) {
      return widget.child;
    }

    if (_view == null || _runner == null) {
      return _introChromeBody(
        l10n: l10n,
        body: const GameStartIntroLoadingIndicator(),
      );
    }

    final line = _view!.currentLine;
    final choice = _view!.currentChoice;

    return _introChromeBody(
      l10n: l10n,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (line != null) ...[
            Text(
              line.text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.center,
              child: CtNinePatchButton(
                onPressed: () => _view!.advanceLine(),
                child: Text(l10n.game_intervention_continue),
              ),
            ),
          ] else if (choice != null) ...[
            ...choice.options.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: CtSpacing.m),
                child: CtNinePatchButton(
                  onPressed: () => _view!.selectOption(entry.key),
                  child: Text(entry.value.text),
                ),
              ),
            ),
          ] else
            const GameStartIntroLoadingIndicator(),
        ],
      ),
    );
  }

  Widget _introChromeBody({
    required AppLocalizations l10n,
    required Widget body,
  }) {
    return CtFullScreenDialogueShell(
      backdrop: widget.child,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _IntroTitle(text: l10n.gameStartIntroOverlay_title),
          const SizedBox(height: 12),
          const CtBrassDivider(),
          const SizedBox(height: 14),
          body,
        ],
      ),
    );
  }
}

/// Cinzel display-font title shown above the brass divider in every
/// non-dismissed state of the intro overlay. Color resolves from
/// `EditorialMonoclePalette.accent`; styling matches the editorial-monocle
/// mockup `SPEC/ui/mockups/OVL10001-game-intro-overlay.html`.
class _IntroTitle extends StatelessWidget {
  const _IntroTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      textAlign: TextAlign.center,
      style: (theme.textTheme.titleMedium ?? const TextStyle(fontSize: 16))
          .copyWith(
            color: EditorialMonoclePalette.accent,
            // 0.05em at Material 3 titleMedium fontSize 16 ≈ 0.8 logical px.
            // Matches `SPEC/ui/mockups/OVL10001-game-intro-overlay.html`
            // `.dialog-title` letter-spacing (mockup uses 0.06em; SPEC/UI
            // restyle table in #2867 R2 pins 0.05em as the dark-theme dialog
            // title contract; both render at the same eye-level on the 16 px
            // Material titleMedium baseline used here).
            letterSpacing: 0.05 * 16,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}
