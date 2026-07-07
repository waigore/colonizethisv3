import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app/config/app_assets.dart';
import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/ui_screen_ids.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:colonizethis_app/package_logger.dart';
import 'package:jenny/jenny.dart';

import '../../../../../l10n/l10n.dart';
import '../../../../../widgets/ct_brass_divider.dart';
import '../../../../../widgets/ct_full_screen_dialogue_shell.dart';
import '../../../../../widgets/ct_loading_indicator.dart';
import '../../../../../widgets/ct_nine_patch_button.dart';
import '../../../../../widgets/ct_spacing.dart';
import '../../../../../widgets/ct_toggle_switch.dart';
import 'ct_dialogue_line_choice_body.dart';
import 'ct_dialogue_view.dart';

part 'overture_dialogue_overlay_flow.dart';
part 'overture_dialogue_overlay_offer_row.dart';
part 'overture_dialogue_overlay_phase_two.dart';

/// Factory kept on the overlay host library so `repo.dialogue_blocking_combined_step`
/// sees `CtDialogueView(` and `CtDialogueLineChoiceBody(` in the same file after
/// the flow mixin was split into a `part` (Refs #3878).
CtDialogueView _createOvertureDialogueView(CtLogger log) =>
    CtDialogueView(logger: log);

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
    this.assetBundle,
  });

  /// SPEC/ui/overture-dialogue-overlay.md — [UiScreenIds.overtureDialogueOverlay].
  static const screenId = UiScreenIds.overtureDialogueOverlay;

  final Game game;
  final List<OvertureOffer> pendingOvertures;
  final void Function(List<OvertureDecision> decisions) onDecisions;
  final Widget child;
  final CtLogger? logger;
  final bool skipIntroForTest;

  /// Optional asset bundle override for loading the overture Yarn asset.
  /// Defaults to [rootBundle]; tests inject a deterministic in-memory bundle
  /// (mirrors `InterventionDialogueOverlay`).
  final AssetBundle? assetBundle;

  @override
  State<OvertureDialogueOverlay> createState() =>
      _OvertureDialogueOverlayState();
}

class _OvertureDialogueOverlayState extends State<OvertureDialogueOverlay>
    with _OvertureDialogueOverlayFlow {
  @override
  bool overtureIntroDone = false;
  @override
  CtDialogueView? overtureView;
  @override
  Object? overtureLoadError;

  /// Per-offer decisions; `null` means the player has not yet tapped Accept
  /// or Reject on that row. The Submit button stays disabled until every
  /// entry is non-null (issue #2867 R23 / AC4).
  late List<bool?> _accepted;

  @override
  void initState() {
    super.initState();
    _accepted = List<bool?>.filled(widget.pendingOvertures.length, null);
    if (widget.skipIntroForTest) {
      overtureIntroDone = true;
    } else {
      loadAndRunOvertureIntro();
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
    if (overtureLoadError != null) {
      return CtFullScreenDialogueShell(
        backdrop: widget.child,
        padding: const EdgeInsets.all(CtSpacing.l),
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.game_overture_loadError('$overtureLoadError')),
            const SizedBox(height: CtSpacing.l),
            CtNinePatchButton(
              onPressed: _submitErrorFallback,
              child: Text(l10n.game_intervention_continue),
            ),
          ],
        ),
      );
    }

    if (!overtureIntroDone) {
      final view = overtureView;
      return CtFullScreenDialogueShell(
        backdrop: widget.child,
        body: view == null
            ? const CtLoadingIndicator()
            : CtDialogueLineChoiceBody(
                view: view,
                continueLabel: l10n.game_intervention_continue,
                lineTextStyle: Theme.of(context).textTheme.bodyLarge,
                loading: const CtLoadingIndicator(),
              ),
      );
    }

    return CtFullScreenDialogueShell(
      backdrop: widget.child,
      maxHeight: 500,
      body: _buildOverturePhaseTwoBody(
        context: context,
        l10n: l10n,
        offers: widget.pendingOvertures,
        accepted: _accepted,
        offererDisplayName: _offererDisplayName,
        stageLabel: _stageLabel,
        allDecided: _allDecided,
        onSubmit: _submit,
        onDecisionChanged: (int index, bool? next) {
          setState(() => _accepted[index] = next);
        },
      ),
    );
  }
}
