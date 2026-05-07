import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app/config/app_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:colonizethis_app/package_logger.dart';
import 'package:jenny/jenny.dart';

import '../../../../l10n/l10n.dart';
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
  late List<bool> _accepted;

  @override
  void initState() {
    super.initState();
    _accepted = List.filled(widget.pendingOvertures.length, true);
    if (widget.skipIntroForTest) {
      _introDone = true;
    } else {
      _loadAndRunIntro();
    }
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
          accepted: _accepted[i],
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
            color: Colors.black54,
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
                        onPressed: () => _submit(),
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
    return Stack(
      children: [
        widget.child,
        Material(
          color: Colors.black54,
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
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.game_overture_intro,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: offers.length,
                      itemBuilder: (context, i) {
                        final offer = offers[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l10n.game_overture_offerLine(
                                    _offererDisplayName(offer.offererGpId),
                                    _stageLabel(l10n, offer.stage),
                                  ),
                                ),
                              ),
                              CtNinePatchButton(
                                onPressed: () {
                                  setState(() => _accepted[i] = true);
                                },
                                child: Text(l10n.game_overture_accept),
                              ),
                              const SizedBox(width: 8),
                              CtNinePatchButton(
                                onPressed: () {
                                  setState(() => _accepted[i] = false);
                                },
                                child: Text(l10n.game_overture_reject),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: CtNinePatchButton(
                        onPressed: _submit,
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
}
