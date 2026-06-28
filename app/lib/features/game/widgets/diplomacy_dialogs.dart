// Dialogs for diplomacy actions that require parameters.
// SPEC: SPEC/ui/grant-or-subsidy-dialog.md (DIPL20001),
// SPEC/ui/diplomacy-panel.md.

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../config/editorial_monocle_palette.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/ct_dialog_shell.dart';
import '../../../widgets/ct_gap.dart';
import '../../../widgets/ct_nine_patch_button.dart';
import '../../../widgets/ct_spacing.dart';

/// Grant or Subsidy dialog widget. Emits [GrantOrSubsidySubmittedEvent] on submit.
///
/// Visual contract: dark editorial-monocle DIPL20001 chrome per
/// `SPEC/ui/grant-or-subsidy-dialog.md` § Layout / wireframe and
/// `SPEC/ui/mockups/DIPL20001-grant-or-subsidy-dialog.html`. All colors resolve
/// from [EditorialMonoclePalette] tokens (no hard-coded hex literals); the
/// stepper renders bespoke `−` / `+` buttons (no Material `IconButton`) to
/// match the per-mockup chrome.
class GrantOrSubsidyDialog extends StatelessWidget {
  const GrantOrSubsidyDialog({
    super.key,
    required this.game,
    required this.humanPlayerId,
    required this.targetFactionId,
    required this.isSubsidy,
    required this.bus,
  });

  final Game game;
  final String humanPlayerId;
  final String targetFactionId;
  final bool isSubsidy;
  final AppEventBus bus;

  int get _treasury {
    for (final p in game.players) {
      if (p.id == humanPlayerId) return p.treasury;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    return CtDialogShell(
      child: _GrantSubsidyAmountBody(
        title: isSubsidy ? l10n.diplomacy_setSubsidy : l10n.diplomacy_grantAid,
        treasury: _treasury,
        isSubsidy: isSubsidy,
        onCancel: () => Navigator.of(context).pop(),
        onSubmit: (amount) {
          Navigator.of(context).pop();
          bus.emit(
            GrantOrSubsidySubmittedEvent(
              targetFactionId: targetFactionId,
              amount: amount,
              isSubsidy: isSubsidy,
            ),
          );
        },
      ),
    );
  }
}

class _GrantSubsidyAmountBody extends StatefulWidget {
  const _GrantSubsidyAmountBody({
    required this.title,
    required this.treasury,
    required this.isSubsidy,
    required this.onCancel,
    required this.onSubmit,
  });

  final String title;
  final int treasury;
  final bool isSubsidy;
  final VoidCallback onCancel;
  final void Function(int amount) onSubmit;

  @override
  State<_GrantSubsidyAmountBody> createState() =>
      _GrantSubsidyAmountBodyState();
}

class _GrantSubsidyAmountBodyState extends State<_GrantSubsidyAmountBody> {
  late int _amount;

  int get _step => widget.isSubsidy ? setSubsidyAmountStep : grantAidAmountStep;

  int _maxAffordable() {
    final t = widget.treasury;
    final s = _step;
    if (t < s) return 0;
    return (t ~/ s) * s;
  }

  int _initialAmount() {
    final maxA = _maxAffordable();
    if (maxA < _step) return 0;
    final d = widget.isSubsidy
        ? setSubsidyDefaultAmount
        : grantAidDefaultAmount;
    final capped = d > maxA ? maxA : d;
    final snapped = (capped ~/ _step) * _step;
    if (snapped >= _step) return snapped;
    return (maxA ~/ _step) * _step;
  }

  bool get _canSubmit =>
      _amount >= _step && _amount <= widget.treasury && _amount % _step == 0;

  @override
  void initState() {
    super.initState();
    _amount = _initialAmount();
  }

  void _decrement() {
    final maxA = _maxAffordable();
    if (maxA < _step) return;
    setState(() {
      final next = _amount - _step;
      _amount = next < _step ? _step : next;
      if (_amount > maxA) _amount = maxA;
    });
  }

  void _increment() {
    final maxA = _maxAffordable();
    if (maxA < _step) return;
    setState(() {
      final next = _amount + _step;
      _amount = next > maxA ? maxA : next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final maxA = _maxAffordable();
    final canAdjust = maxA >= _step;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DialogTitle(title: widget.title),
        const SizedBox(height: 10),
        _TreasuryRow(
          label: l10n.diplomacy_treasuryStep(widget.treasury, _step),
        ),
        const SizedBox(height: 10),
        const _ThinDivider(),
        CtGap.ml,
        _AmountStepper(
          amount: _amount,
          amountText: l10n.diplomacy_currencyAmount(_amount),
          canAdjust: canAdjust,
          onDecrement: _decrement,
          onIncrement: _increment,
        ),
        if (!canAdjust) ...[
          CtGap.m,
          _BelowMinimumWarning(
            text: l10n.diplomacy_treasuryBelowMinimum(_step),
          ),
        ],
        CtGap.l,
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            CtNinePatchButton(
              onPressed: widget.onCancel,
              child: Text(l10n.common_cancel),
            ),
            CtGap.wm,
            CtNinePatchButton(
              enabled: _canSubmit,
              onPressed: () => widget.onSubmit(_amount),
              child: Text(l10n.game_callToArms_submit),
            ),
          ],
        ),
      ],
    );
  }
}

/// Dialog title — display font, `--accent` color, `letterSpacing = fontSize * 0.05`.
class _DialogTitle extends StatelessWidget {
  const _DialogTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.titleMedium ?? const TextStyle(fontSize: 16);
    final double fontSize = base.fontSize ?? 16;
    final style = base.copyWith(
      color: EditorialMonoclePalette.accent,
      letterSpacing: fontSize * 0.05,
    );
    return Text(
      title,
      key: const Key('grantOrSubsidyDialogTitle'),
      style: style,
    );
  }
}

/// Treasury info line — body slot, `--muted` color.
class _TreasuryRow extends StatelessWidget {
  const _TreasuryRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.bodySmall ?? const TextStyle();
    final style = base.copyWith(color: EditorialMonoclePalette.muted);
    return Text(
      label,
      key: const Key('grantOrSubsidyDialogTreasury'),
      style: style,
    );
  }
}

/// 1 dp solid divider in `--border` between treasury row and stepper. Matches
/// `.divider-thin` in `SPEC/ui/mockups/DIPL20001-grant-or-subsidy-dialog.html`.
class _ThinDivider extends StatelessWidget {
  const _ThinDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('grantOrSubsidyDialogThinDivider'),
      height: 1,
      decoration: BoxDecoration(
        color: EditorialMonoclePalette.border,
      ),
    );
  }
}

/// Centered minus/amount/plus row matching `.stepper` in the DIPL20001 mockup.
class _AmountStepper extends StatelessWidget {
  const _AmountStepper({
    required this.amount,
    required this.amountText,
    required this.canAdjust,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int amount;
  final String amountText;
  final bool canAdjust;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StepperButton(
          buttonKey: const Key('diplo_amount_minus'),
          label: '\u2212',
          enabled: canAdjust,
          background: EditorialMonoclePalette.bgDeep,
          borderColor: EditorialMonoclePalette.border,
          labelColor: EditorialMonoclePalette.muted,
          onTap: onDecrement,
        ),
        const SizedBox(width: 14),
        _AmountLabel(text: amountText),
        const SizedBox(width: 14),
        _StepperButton(
          buttonKey: const Key('diplo_amount_plus'),
          label: '+',
          enabled: canAdjust,
          background: EditorialMonoclePalette.surfaceLite,
          borderColor: EditorialMonoclePalette.accentDim,
          labelColor: EditorialMonoclePalette.accent,
          onTap: onIncrement,
        ),
      ],
    );
  }
}

/// Bespoke stepper button. The mockup uses sharp 1 dp borders and monospace
/// `−` / `+` glyphs (not Material icons), so a `GestureDetector` over a
/// `DecoratedBox` reproduces the chrome with the disable opacity convention
/// used by the rest of the dark catalog.
class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.buttonKey,
    required this.label,
    required this.enabled,
    required this.background,
    required this.borderColor,
    required this.labelColor,
    required this.onTap,
  });

  final Key buttonKey;
  final String label;
  final bool enabled;
  final Color background;
  final Color borderColor;
  final Color labelColor;
  final VoidCallback onTap;

  static const double _minWidth = 40;
  static const double _height = 36;
  static const double _disabledOpacity = 0.3;

  @override
  Widget build(BuildContext context) {
    final Widget body = Container(
      constraints: const BoxConstraints(
        minWidth: _minWidth,
        minHeight: _height,
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: CtSpacing.m,
      ),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: labelColor,
          fontFamily: 'monospace',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          height: 1.0,
        ),
      ),
    );
    return Opacity(
      key: buttonKey,
      opacity: enabled ? 1.0 : _disabledOpacity,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: body,
      ),
    );
  }
}

/// Amount label — display font (headlineSmall slot), `--fg` color,
/// `letterSpacing = fontSize * 0.04`, min 80 dp content width.
class _AmountLabel extends StatelessWidget {
  const _AmountLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.headlineSmall ?? const TextStyle(fontSize: 24);
    final double fontSize = base.fontSize ?? 24;
    final style = base.copyWith(
      color: EditorialMonoclePalette.fg,
      letterSpacing: fontSize * 0.04,
      fontWeight: FontWeight.w700,
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 80),
      child: Text(
        text,
        key: const Key('grantOrSubsidyDialogAmount'),
        textAlign: TextAlign.center,
        style: style,
      ),
    );
  }
}

/// Below-minimum warning — italic body slot, `--danger` color.
class _BelowMinimumWarning extends StatelessWidget {
  const _BelowMinimumWarning({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.bodySmall ?? const TextStyle();
    final style = base.copyWith(
      color: EditorialMonoclePalette.danger,
      fontStyle: FontStyle.italic,
    );
    return Text(
      text,
      key: const Key('grantOrSubsidyDialogWarning'),
      style: style,
    );
  }
}
