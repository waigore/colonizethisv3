import 'package:flutter/material.dart';
import 'package:jenny/jenny.dart';

import '../../../../widgets/ct_nine_patch_button.dart';
import '../../../../widgets/ct_spacing.dart';
import 'ct_dialogue_view.dart';

/// Shared body for blocking Jenny dialogue overlays that renders the narrative
/// line and the Yarn choice options as a single, combined presentation.
///
/// SPEC/ui/ct-dialogue-view.md § Combined line+choice presentation (Refs
/// #3628). The four blocking overlays (`GameStartIntroOverlay`,
/// `TribeFirstContactOverlay`, `OvertureDialogueOverlay`,
/// `InterventionDialogueOverlay`) previously each duplicated the same
/// mutually-exclusive `line` / `choice` branches, which dropped the narrative
/// text the moment the choice step appeared. This widget centralises the
/// retained-line behaviour so the message stays visible above the option
/// buttons, eliminating the message-only-then-option-only flicker.
///
/// Rendering, in priority order:
/// 1. **Active line** ([CtDialogueView.currentLine] non-null): the line text
///    plus a single `continueLabel` [CtNinePatchButton] that calls
///    [CtDialogueView.advanceLine].
/// 2. **Active choice** ([CtDialogueView.currentChoice] non-null): the retained
///    [CtDialogueView.contextLine] text (when present) above one stretched
///    [CtNinePatchButton] per option, each calling
///    [CtDialogueView.selectOption].
/// 3. **Transient** (no active line/choice but a retained context line): the
///    context line text above the [loading] widget, so the message does not
///    flash away between the line advance and the next Jenny event.
/// 4. **Idle / loading**: the [loading] widget alone.
class CtDialogueLineChoiceBody extends StatelessWidget {
  const CtDialogueLineChoiceBody({
    super.key,
    required this.view,
    required this.continueLabel,
    required this.loading,
    this.lineTextStyle,
    this.lineTextAlign = TextAlign.start,
    this.continueAlignment = Alignment.centerRight,
    this.gap = CtSpacing.l,
    this.optionSpacing = CtSpacing.m,
  });

  /// The Jenny adapter driving line / choice state.
  final CtDialogueView view;

  /// Localized label for the line-step continue affordance (typically
  /// `l10n.game_intervention_continue`).
  final String continueLabel;

  /// Loading / spinner widget shown while no line or choice is active.
  final Widget loading;

  /// Text style for both the active line and the retained context line.
  final TextStyle? lineTextStyle;

  /// Horizontal alignment of the line text and retained context line text.
  final TextAlign lineTextAlign;

  /// Alignment of the line-step continue button within the column.
  final AlignmentGeometry continueAlignment;

  /// Vertical gap between narrative text and the button block.
  final double gap;

  /// Vertical gap between stacked option buttons.
  final double optionSpacing;

  @override
  Widget build(BuildContext context) {
    final line = view.currentLine;
    if (line != null) {
      return _buildLineStep(line.text);
    }

    final choice = view.currentChoice;
    if (choice != null) {
      return _buildChoiceStep(choice);
    }

    final contextLine = view.contextLine;
    if (contextLine != null) {
      return _buildTransientStep(contextLine.text);
    }

    return loading;
  }

  Widget _lineText(String text) =>
      Text(text, style: lineTextStyle, textAlign: lineTextAlign);

  Widget _buildLineStep(String text) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _lineText(text),
        SizedBox(height: gap),
        Align(
          alignment: continueAlignment,
          child: CtNinePatchButton(
            onPressed: view.advanceLine,
            child: Text(continueLabel),
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceStep(DialogueChoice choice) {
    final contextLine = view.contextLine;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (contextLine != null) ...[
          _lineText(contextLine.text),
          SizedBox(height: gap),
        ],
        ...choice.options.asMap().entries.map(
          (entry) => Padding(
            padding: EdgeInsets.only(bottom: optionSpacing),
            child: CtNinePatchButton(
              onPressed: () => view.selectOption(entry.key),
              child: Text(entry.value.text),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransientStep(String text) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _lineText(text),
        SizedBox(height: gap),
        loading,
      ],
    );
  }
}
