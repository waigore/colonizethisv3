import 'package:colonizethis_app/config/ui_screen_ids.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app_ui_chrome/widgets/ct_brass_divider.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';

import '../../../../../widgets/ct_full_screen_dialogue_shell.dart';
import '../../../../../widgets/ct_nine_patch_button.dart';
import '../../../../../widgets/ct_spacing.dart';
import 'dialogue_tristate_decision_row.dart';
import 'ftp_dialogue_offer_row.dart';

/// Blocking overlay: human Accept/Reject pending Favored Trading Partner offers.
class FtpDialogueOverlay extends StatefulWidget {
  const FtpDialogueOverlay({
    super.key,
    required this.game,
    required this.pending,
    required this.onDecisions,
    required this.child,
  });

  static const screenId = UiScreenIds.ftpDialogueOverlay;

  final Game game;
  final List<FtpOffer> pending;
  final void Function(List<FtpDecision> decisions) onDecisions;
  final Widget child;

  @override
  State<FtpDialogueOverlay> createState() => _FtpDialogueOverlayState();
}

class _FtpDialogueOverlayState extends State<FtpDialogueOverlay> {
  late List<bool?> _accept;

  @override
  void initState() {
    super.initState();
    _accept = List<bool?>.filled(widget.pending.length, null);
  }

  bool get _allDecided => dialogueTristateAllDecided(_accept);

  String _gpName(String gpId) {
    final p = widget.game.playerById(gpId);
    return p?.displayName ?? gpId;
  }

  void _submit() {
    final decisions = <FtpDecision>[];
    for (var i = 0; i < widget.pending.length; i++) {
      final offer = widget.pending[i];
      decisions.add(
        FtpDecision(
          proposerGpId: offer.proposerGpId,
          targetGpId: offer.targetGpId,
          accepted: _accept[i] ?? false,
        ),
      );
    }
    widget.onDecisions(decisions);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final ThemeData theme = Theme.of(context);
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
    return CtFullScreenDialogueShell(
      backdrop: widget.child,
      maxHeight: 500,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.game_ftp_title, style: titleStyle),
          const SizedBox(height: CtSpacing.m),
          Text(l10n.game_ftp_intro, style: introStyle),
          const SizedBox(height: CtSpacing.ml),
          const CtBrassDivider(),
          const SizedBox(height: CtSpacing.ml),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.pending.length,
            itemBuilder: (context, i) {
              final offer = widget.pending[i];
              final name = _gpName(offer.proposerGpId);
              return FtpDialogueOfferRow(
                rowIndex: i,
                offererName: name,
                acceptLabel: l10n.game_ftp_accept,
                rejectLabel: l10n.game_ftp_reject,
                acceptEffects: favoredTradingPartnerAcceptEffectLines(name),
                rejectEffect: favoredTradingPartnerRejectEffectLine(name),
                decision: _accept[i],
                onDecisionChanged: (bool? next) {
                  setState(() => _accept[i] = next);
                },
              );
            },
          ),
          const SizedBox(height: CtSpacing.m),
          Align(
            alignment: Alignment.centerRight,
            child: CtNinePatchButton(
              key: const ValueKey<String>('ftpSubmitButton'),
              enabled: _allDecided,
              onPressed: _allDecided ? _submit : null,
              child: Text(l10n.game_callToArms_submit),
            ),
          ),
        ],
      ),
    );
  }
}
