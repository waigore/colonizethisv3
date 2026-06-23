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
/// 1. **Collapsed line+option** ([CtDialogueView.currentLine] non-null and
///    [CtDialogueView.pendingSingleOptionLabel] non-null): the line text plus a
///    single [CtNinePatchButton] labelled with the Yarn option text, wired to
///    [CtDialogueView.confirmCombinedLineOption]. One tap advances the line and
///    selects the sole trailing option, so a `line -> <single option>` node is
///    shown once and confirmed once (no duplicate step). Refs #3628.
/// 2. **Active line** ([CtDialogueView.currentLine] non-null): the line text
///    plus a single `continueLabel` [CtNinePatchButton] that calls
///    [CtDialogueView.advanceLine].
/// 3. **Active choice** ([CtDialogueView.currentChoice] non-null): the retained
///    [CtDialogueView.contextLine] text (when present) above one stretched
///    [CtNinePatchButton] per option, each calling
///    [CtDialogueView.selectOption]. Only reached for choices with two or more
///    options; single-option choices are collapsed into the line step above.
/// 4. **Transient** (no active line/choice but a retained context line): the
///    context line text above the [loading] widget, so the message does not
///    flash away between the line advance and the next Jenny event.
/// 5. **Idle / loading**: the [loading] widget alone.
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
      final collapsedLabel = view.pendingSingleOptionLabel;
      if (collapsedLabel != null) {
        return _buildCollapsedStep(line.text, collapsedLabel);
      }
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

  /// Combined line + single-option step (Refs #3628): the narrative text above
  /// one button labelled with the Yarn option [optionLabel] (e.g. `I shall.`).
  /// Tapping it advances the line and selects the sole option in one action via
  /// [CtDialogueView.confirmCombinedLineOption].
  Widget _buildCollapsedStep(String text, String optionLabel) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _lineText(text),
        SizedBox(height: gap),
        Align(
          alignment: continueAlignment,
          child: CtNinePatchButton(
            onPressed: view.confirmCombinedLineOption,
            child: Text(optionLabel),
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
