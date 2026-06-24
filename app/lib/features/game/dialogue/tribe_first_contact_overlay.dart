import 'package:colonizethis_app/config/app_assets.dart';
import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/ui_screen_ids.dart';
import 'package:colonizethis_app/package_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jenny/jenny.dart';

import '../../../../l10n/l10n.dart';
import '../../../../widgets/ct_brass_divider.dart';
import '../../../../widgets/ct_full_screen_dialogue_shell.dart';
import '../../../../widgets/ct_nine_patch_button.dart';
import '../../../../widgets/ct_spacing.dart';
import 'ct_dialogue_line_choice_body.dart';
import 'game_start_intro_overlay.dart';
import 'ct_dialogue_view.dart';

/// Blocking herald when the human GP first discovers a Tribe faction.
/// SPEC/ui/tribe-first-contact-overlay.md (OVL80001).
class TribeFirstContactOverlay extends StatefulWidget {
  const TribeFirstContactOverlay({
    super.key,
    required this.tribeName,
    required this.capitalName,
    required this.onDismissed,
    required this.child,
    this.logger,
    this.assetBundle,
  });

  static const screenId = UiScreenIds.tribeFirstContactOverlay;

  final String tribeName;
  final String capitalName;
  final VoidCallback onDismissed;
  final Widget child;
  final CtLogger? logger;
  final AssetBundle? assetBundle;

  @override
  State<TribeFirstContactOverlay> createState() =>
      _TribeFirstContactOverlayState();
}

class _TribeFirstContactOverlayState extends State<TribeFirstContactOverlay> {
  static const String _kNode = 'tribe_first_contact';

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
      if (!project.nodes.containsKey(_kNode)) {
        throw StateError(
          'Tribe first-contact node "$_kNode" not found in '
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
      await runner.startDialogue(_kNode);
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
            _TribeFirstContactTitle(text: l10n.tribeFirstContactOverlay_title),
            const SizedBox(height: CtSpacing.ml),
            const CtBrassDivider(),
            const SizedBox(height: 14),
            Text(
              l10n.tribeFirstContactOverlay_loadError('$_loadError'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: EditorialMonoclePalette.accentDim,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: CtSpacing.l),
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
      return _chromeBody(
        l10n: l10n,
        body: const GameStartIntroLoadingIndicator(),
      );
    }

    return _chromeBody(
      l10n: l10n,
      body: CtDialogueLineChoiceBody(
        view: _view!,
        continueLabel: l10n.game_intervention_continue,
        lineTextStyle: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
        lineTextAlign: TextAlign.center,
        continueAlignment: Alignment.center,
        loading: const GameStartIntroLoadingIndicator(),
      ),
    );
  }

  Widget _chromeBody({required AppLocalizations l10n, required Widget body}) {
    return CtFullScreenDialogueShell(
      backdrop: widget.child,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TribeFirstContactTitle(text: l10n.tribeFirstContactOverlay_title),
          const SizedBox(height: CtSpacing.ml),
          const CtBrassDivider(),
          const SizedBox(height: 14),
          body,
        ],
      ),
    );
  }
}

class _TribeFirstContactTitle extends StatelessWidget {
  const _TribeFirstContactTitle({required this.text});

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
            letterSpacing: 0.05 * 16,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}
