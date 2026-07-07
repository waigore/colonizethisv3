part of 'overture_dialogue_overlay.dart';

extension _OvertureDialogueOverlayBuild on _OvertureDialogueOverlayState {
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

  String _stageLabel(AppLocalizations l10n, OvertureStage stage) {
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

  Widget buildOvertureDialogueOverlay(BuildContext context) {
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
        onDecisionChanged: _updateOvertureDecision,
      ),
    );
  }
}
