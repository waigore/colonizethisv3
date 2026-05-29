import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/ui_screen_ids.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../widgets/ct_brass_divider.dart';
import '../../../../widgets/ct_dialog_shell.dart';
import '../../../../widgets/ct_nine_patch_button.dart';

/// Blocking overlay: human ally accepts or refuses each pending call to arms.
class CallToArmsDialogueOverlay extends StatefulWidget {
  const CallToArmsDialogueOverlay({
    super.key,
    required this.game,
    required this.pending,
    required this.onDecisions,
    required this.child,
  });

  static const screenId = UiScreenIds.callToArmsDialogueOverlay;

  final Game game;
  final List<CallToArmsPending> pending;
  final void Function(List<CallToArmsDecision> decisions) onDecisions;
  final Widget child;

  @override
  State<CallToArmsDialogueOverlay> createState() =>
      _CallToArmsDialogueOverlayState();
}

class _CallToArmsDialogueOverlayState extends State<CallToArmsDialogueOverlay> {
  late List<bool> _join;

  @override
  void initState() {
    super.initState();
    _join = List.filled(widget.pending.length, true);
  }

  String _gpName(String gpId) {
    final p = widget.game.playerById(gpId);
    return p?.displayName ?? gpId;
  }

  void _submit() {
    final decisions = <CallToArmsDecision>[];
    for (var i = 0; i < widget.pending.length; i++) {
      final c = widget.pending[i];
      decisions.add(
        CallToArmsDecision(
          allyGpId: c.allyGpId,
          defenderGpId: c.defenderGpId,
          aggressorGpId: c.aggressorGpId,
          accepted: _join[i],
        ),
      );
    }
    widget.onDecisions(decisions);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final ThemeData theme = Theme.of(context);
    final items = widget.pending;
    final TextStyle baseTitle =
        theme.textTheme.titleMedium ?? const TextStyle(fontSize: 16);
    final TextStyle titleStyle = baseTitle.copyWith(
      color: EditorialMonoclePalette.accent,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.05 * (baseTitle.fontSize ?? 16),
    );
    final TextStyle baseIntro =
        theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14);
    final TextStyle introStyle = baseIntro.copyWith(
      color: EditorialMonoclePalette.muted,
      fontStyle: FontStyle.italic,
    );
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
                      l10n.game_callToArms_title,
                      style: titleStyle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.game_callToArms_intro,
                      style: introStyle,
                    ),
                    const SizedBox(height: 12),
                    const CtBrassDivider(),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final c = items[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  l10n.game_callToArms_prompt(
                                    _gpName(c.defenderGpId),
                                    _gpName(c.aggressorGpId),
                                  ),
                                ),
                              ),
                              CtNinePatchButton(
                                onPressed: () {
                                  setState(() => _join[i] = true);
                                },
                                child: Text(l10n.game_callToArms_join),
                              ),
                              const SizedBox(width: 8),
                              CtNinePatchButton(
                                onPressed: () {
                                  setState(() => _join[i] = false);
                                },
                                child: Text(l10n.game_callToArms_refuse),
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
