part of 'ct_toggle_switch.dart';

class _CtToggleSwitchKnob extends StatelessWidget {
  const _CtToggleSwitchKnob({
    required this.fill,
    required this.border,
    required this.glowColor,
    required this.glowAlpha,
    required this.duration,
  });

  final Color fill;
  final Color border;
  final Color glowColor;
  final double glowAlpha;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final List<BoxShadow>? glow = glowAlpha > 0
        ? <BoxShadow>[
            BoxShadow(
              color: glowColor.withValues(
                alpha: glowAlpha,
              ),
              spreadRadius: CtToggleSwitch.glowSpread,
              blurRadius: 0,
            ),
          ]
        : null;
    return AnimatedContainer(
      key: const ValueKey<String>('ctToggleSwitchKnob'),
      duration: duration,
      curve: CtToggleSwitch.animationCurve,
      width: CtToggleSwitch.knobSize,
      height: CtToggleSwitch.knobSize,
      decoration: BoxDecoration(
        color: fill,
        border: Border.all(
          color: border,
          width: CtToggleSwitch.borderWidth,
        ),
        boxShadow: glow,
      ),
    );
  }
}
