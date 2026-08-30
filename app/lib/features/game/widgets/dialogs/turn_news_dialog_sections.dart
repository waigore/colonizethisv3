// Gazette / court / spy sections for DLG50001 Turn News.
// SPEC/ui/turn-news-dialog.md.

import 'package:flutter/material.dart';

import '../../../../widgets/ct_spacing.dart';

class TurnNewsGazetteSection extends StatelessWidget {
  const TurnNewsGazetteSection({
    super.key,
    required this.isEmpty,
    required this.hasCourt,
    required this.lines,
    required this.emptyLabel,
    required this.mutedStyle,
    required this.bodyStyle,
  });

  final bool isEmpty;
  final bool hasCourt;
  final List<String> lines;
  final String emptyLabel;
  final TextStyle mutedStyle;
  final TextStyle bodyStyle;

  @override
  Widget build(BuildContext context) {
    if (isEmpty && !hasCourt) {
      return Text(emptyLabel, style: mutedStyle);
    }
    if (isEmpty) {
      return const SizedBox.shrink();
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 320),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: lines.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: CtSpacing.m),
          child: Text(lines[i], style: bodyStyle),
        ),
      ),
    );
  }
}

class TurnNewsSpyFooter extends StatelessWidget {
  const TurnNewsSpyFooter({
    super.key,
    required this.label,
    required this.mutedStyle,
    required this.onOpenIntelligence,
  });

  final String label;
  final TextStyle mutedStyle;
  final VoidCallback onOpenIntelligence;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: CtSpacing.m),
      child: InkWell(
        onTap: onOpenIntelligence,
        child: Text(label, style: mutedStyle),
      ),
    );
  }
}

class TurnNewsCourtBlock extends StatelessWidget {
  const TurnNewsCourtBlock({
    super.key,
    required this.body,
    required this.openEventsLabel,
    required this.mutedStyle,
    this.onOpenEvents,
  });

  final String body;
  final String openEventsLabel;
  final TextStyle mutedStyle;
  final VoidCallback? onOpenEvents;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpenEvents,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: CtSpacing.xs,
        runSpacing: CtSpacing.xs,
        children: [
          Text(body, style: mutedStyle),
          if (onOpenEvents != null)
            Text(
              openEventsLabel,
              style: mutedStyle.copyWith(
                decoration: TextDecoration.underline,
                decorationColor: mutedStyle.color,
              ),
            ),
        ],
      ),
    );
  }
}
