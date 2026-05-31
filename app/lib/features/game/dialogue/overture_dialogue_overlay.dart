import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app/config/app_assets.dart';
import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/ui_screen_ids.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:colonizethis_app/package_logger.dart';
import 'package:jenny/jenny.dart';

import '../../../../l10n/l10n.dart';
import '../../../../widgets/ct_brass_divider.dart';
import '../../../../widgets/ct_dialog_shell.dart';
import '../../../../widgets/ct_loading_indicator.dart';
import '../../../../widgets/ct_nine_patch_button.dart';
import 'ct_dialogue_view.dart';

/// Modal overture dialogue: Jenny-driven intro line then Accept/Reject per offer
/// and Submit. SPEC/ui/dialogue-presentation.md, SPEC/ai/dialogue-content-and-yarn.md.
class OvertureDialogueOverlay extends StatefulWidget {
  const OvertureDialogueOverlay({
    super.key,
    required this.game,
    required this.pendingOvertures,
    required this.onDecisions,
    required this.child,
    this.logger,

    /// When true, skip Jenny intro and show list immediately. For tests only.
    this.skipIntroForTest = false,
  });

  /// SPEC/ui/overture-dialogue-overlay.md — [UiScreenIds.overtureDialogueOverlay].
  static const screenId = UiScreenIds.overtureDialogueOverlay;

  final Game game;
  final List<OvertureOffer> pendingOvertures;
  final void Function(List<OvertureDecision> decisions) onDecisions;
  final Widget child;
  final CtLogger? logger;
  final bool skipIntroForTest;

  @override
  State<OvertureDialogueOverlay> createState() =>
      _OvertureDialogueOverlayState();
}

class _OvertureDialogueOverlayState extends State<OvertureDialogueOverlay> {
  static const String _kOvertureNode = 'DialoguePoint/overture_target_response';

  bool _introDone = false;
  CtDialogueView? _view;
  Object? _loadError;

  /// Per-offer decisions; `null` means the player has not yet tapped Accept
  /// or Reject on that row. The Submit button stays disabled until every
  /// entry is non-null (issue #2867 R23 / AC4).
  late List<bool?> _accepted;

  @override
  void initState() {
    super.initState();
    _accepted = List<bool?>.filled(widget.pendingOvertures.length, null);
    if (widget.skipIntroForTest) {
      _introDone = true;
    } else {
      _loadAndRunIntro();
    }
  }

  /// True when every pending overture row has a non-null decision; gates the
  /// phase-2 Submit `CtNinePatchButton` per #2867 R23 (`SPEC/ui/overture-dialogue-overlay.md`
  /// § Acceptance Criteria — non-null decision required).
  bool get _allDecided {
    for (final bool? value in _accepted) {
      if (value == null) return false;
    }
    return true;
  }

  Future<void> _loadAndRunIntro() async {
    final log = widget.logger ?? packageLogger('dialogue');
    try {
      final text = await rootBundle.loadString(kDialogueOvertureAsset);
      final project = YarnProject();
      project.parse(text);
      if (!project.nodes.containsKey(_kOvertureNode)) {
        throw StateError(
          'Overture node "$_kOvertureNode" not found in $kDialogueOvertureAsset',
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
      });
      await runner.startDialogue(_kOvertureNode);
      if (!mounted) return;
      setState(() => _introDone = true);
    } catch (e, st) {
      log.e(
        'ui:dialogue: failed to load overture intro',
        error: e,
        stackTrace: st,
      );
      if (mounted) setState(() => _loadError = e);
    }
  }

  String _offererDisplayName(String offererGpId) {
    for (final p in widget.game.players) {
      if (p.id == offererGpId) return p.displayName;
    }
    return offererGpId;
  }

  static String _stageLabel(AppLocalizations l10n, OvertureStage stage) {
    switch (stage) {
      case OvertureStage.tradeConsulate:
        return l10n.turnNews_stage_tradeConsulate;
      case OvertureStage.embassy:
        return l10n.turnNews_stage_embassy;
      case OvertureStage.nap:
        return l10n.turnNews_stage_nap;
      case OvertureStage.joinEmpire:
        return l10n.turnNews_stage_joinEmpire;
      case OvertureStage.none:
        return l10n.province_fleetMission_none;
    }
  }

  void _submit() {
    final decisions = <OvertureDecision>[];
    for (var i = 0; i < widget.pendingOvertures.length; i++) {
      final offer = widget.pendingOvertures[i];
      decisions.add(
        OvertureDecision(
          offererGpId: offer.offererGpId,
          targetFactionId: offer.targetFactionId,
          stage: offer.stage,
          accepted: _accepted[i] ?? true,
        ),
      );
    }
    widget.onDecisions(decisions);
  }

  /// Degraded error-state submit: the Yarn intro failed to load, so the
  /// per-offer Accept/Reject UI is never shown. Emit a deterministic
  /// `accepted == true` decision per offer so the host can still resume
  /// turn resolution (`SPEC/ui/overture-dialogue-overlay.md` § AC error
  /// variant). This bypasses the R23 non-null gate by design — the player
  /// has no interactive choice in this variant.
  void _submitErrorFallback() {
    final decisions = <OvertureDecision>[];
    for (final OvertureOffer offer in widget.pendingOvertures) {
      decisions.add(
        OvertureDecision(
          offererGpId: offer.offererGpId,
          targetFactionId: offer.targetFactionId,
          stage: offer.stage,
          accepted: true,
        ),
      );
    }
    widget.onDecisions(decisions);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    if (_loadError != null) {
      return Stack(
        children: [
          widget.child,
          Material(
            color: EditorialMonoclePalette.dialogScrim,
            child: Center(
              child: CtDialogShell(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.game_overture_loadError('$_loadError')),
                      const SizedBox(height: 16),
                      CtNinePatchButton(
                        onPressed: _submitErrorFallback,
                        child: Text(l10n.game_intervention_continue),
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

    if (!_introDone) {
      final line = _view?.currentLine;
      final choice = _view?.currentChoice;
      return Stack(
        children: [
          widget.child,
          Material(
            color: EditorialMonoclePalette.dialogScrim,
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
                            child: Text(l10n.game_intervention_continue),
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
                        const CtLoadingIndicator(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Phase 2: list of offers with Accept/Reject + Submit
    final offers = widget.pendingOvertures;
    final ThemeData theme = Theme.of(context);
    final TextStyle titleStyle = _phaseTwoTitleStyle(theme);
    final TextStyle introStyle = _phaseTwoIntroStyle(theme);
    return Stack(
      children: [
        widget.child,
        Material(
          color: EditorialMonoclePalette.dialogScrim,
          child: Center(
            child: CtDialogShell(
              maxWidth: 520,
              maxHeight: 500,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.game_overture_title,
                      key: const ValueKey<String>('overtureTitle'),
                      style: titleStyle,
                    ),
                    const SizedBox(height: _titleToDividerGap),
                    const CtBrassDivider(
                      key: ValueKey<String>('overtureBrassDivider'),
                    ),
                    const SizedBox(height: _dividerToIntroGap),
                    Text(
                      l10n.game_overture_intro,
                      key: const ValueKey<String>('overtureIntro'),
                      style: introStyle,
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: offers.length,
                      itemBuilder: (context, i) {
                        final offer = offers[i];
                        return _OvertureOfferRow(
                          offerer: _offererDisplayName(offer.offererGpId),
                          stageLabel: _stageLabel(l10n, offer.stage),
                          acceptLabel: l10n.game_overture_accept,
                          rejectLabel: l10n.game_overture_reject,
                          onAccept: () {
                            setState(() => _accepted[i] = true);
                          },
                          onReject: () {
                            setState(() => _accepted[i] = false);
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: CtNinePatchButton(
                        key: const ValueKey<String>('overtureSubmitButton'),
                        enabled: _allDecided,
                        onPressed: _allDecided ? _submit : null,
                        child: Text(l10n.game_callToArms_submit),
                      ),
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

  /// Phase-2 title style per #2867 R2 / R21: `--accent` color and a 0.05em
  /// letter-spacing computed from the resolved title `fontSize` so the
  /// canonical letter-spacing scales with theme overrides.
  TextStyle _phaseTwoTitleStyle(ThemeData theme) {
    final TextStyle base =
        theme.textTheme.titleMedium ?? const TextStyle(fontSize: 16);
    final double fontSize = base.fontSize ?? 16;
    return base.copyWith(
      color: EditorialMonoclePalette.accent,
      letterSpacing: fontSize * _titleLetterSpacingEm,
    );
  }

  /// Phase-2 intro style per #2867 R5 / R21: italic body text in `--muted`.
  TextStyle _phaseTwoIntroStyle(ThemeData theme) =>
      (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
        color: EditorialMonoclePalette.muted,
        fontStyle: FontStyle.italic,
      );

  /// Canonical title letter-spacing factor per #2867 R2 (0.05em).
  static const double _titleLetterSpacingEm = 0.05;

  /// Vertical gap between phase-2 title and the [CtBrassDivider].
  static const double _titleToDividerGap = 8;

  /// Vertical gap between the [CtBrassDivider] and the intro line.
  static const double _dividerToIntroGap = 8;
}

/// Phase-2 offer row. Splits the offerer display name and the localized
/// stage label into two `Text` widgets so they can paint distinct
/// editorial-monocle palette colors per #2867 R22 (`--accent` for the
/// offerer, `--muted` for the stage label).
class _OvertureOfferRow extends StatelessWidget {
  const _OvertureOfferRow({
    required this.offerer,
    required this.stageLabel,
    required this.acceptLabel,
    required this.rejectLabel,
    required this.onAccept,
    required this.onReject,
  });

  final String offerer;
  final String stageLabel;
  final String acceptLabel;
  final String rejectLabel;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle base =
        theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14);
    final TextStyle offererStyle = base.copyWith(
      color: EditorialMonoclePalette.accent,
      fontWeight: FontWeight.w600,
    );
    final TextStyle separatorStyle = base.copyWith(
      color: EditorialMonoclePalette.muted,
    );
    final TextStyle stageStyle = base.copyWith(
      color: EditorialMonoclePalette.muted,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    offerer,
                    key: const ValueKey<String>('overtureOfferOfferer'),
                    style: offererStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  ': ',
                  key: const ValueKey<String>('overtureOfferSeparator'),
                  style: separatorStyle,
                ),
                Flexible(
                  child: Text(
                    stageLabel,
                    key: const ValueKey<String>('overtureOfferStage'),
                    style: stageStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          CtNinePatchButton(
            onPressed: onAccept,
            child: Text(acceptLabel),
          ),
          const SizedBox(width: 8),
          CtNinePatchButton(
            onPressed: onReject,
            child: Text(rejectLabel),
          ),
        ],
      ),
    );
  }
}
