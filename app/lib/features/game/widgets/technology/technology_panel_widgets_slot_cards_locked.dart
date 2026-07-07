part of 'technology_panel_widgets.dart';

/// Locked fourth-slot placeholder card rendered when
/// `player.researchSlots < 4`.
///
/// SPEC/ui/technology-panel.md § Slot behaviour > Locked slot 4
/// (University). Refs #2864 S0/S3.
class LockedResearchSlotCard extends StatelessWidget {
  const LockedResearchSlotCard({super.key, required this.slotNumber});

  final int slotNumber;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    return Opacity(
      opacity: kTechnologyLockedSlotOpacity,
      child: _SlotCardChrome(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.technologyPanel_lockedSlotLabel(slotNumber),
              style: TextStyle(
                color: EditorialMonoclePalette.fg,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.04,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                l10n.technologyPanel_lockedSlotFootnote,
                style: TextStyle(
                  color: EditorialMonoclePalette.muted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotCardChrome extends StatelessWidget {
  const _SlotCardChrome({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: _technologyDarkSurfaceGradient(),
        border: Border.all(
          color: EditorialMonoclePalette.border,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: CtSpacing.m,
        ),
        child: child,
      ),
    );
  }
}
