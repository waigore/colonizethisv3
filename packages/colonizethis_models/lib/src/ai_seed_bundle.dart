// Sub-seeds derived from turnSeed[P, T] for deterministic AI. SPEC/ai/ai-architecture.md, ai-planner.md.

/// Bundle of sub-seeds for one AI turn. All randomness in colonizethis_ai uses these.
class AISeedBundle {
  const AISeedBundle({
    required this.perceptionSeed,
    required this.goalSeed,
    required this.economySeed,
    required this.militarySeed,
    required this.diplomacySeed,
    required this.researchSeed,
    required this.tacticalSeed,
    required this.dialogueSeed,
    required this.agendaSeed,
  });

  final int perceptionSeed;
  final int goalSeed;
  final int economySeed;
  final int militarySeed;
  final int diplomacySeed;
  final int researchSeed;
  final int tacticalSeed;
  final int dialogueSeed;
  final int agendaSeed;

  /// Derives sub-seeds from [turnSeed] using a simple hash chain.
  /// Same turnSeed → same bundle (deterministic).
  factory AISeedBundle.fromTurnSeed(int turnSeed) {
    const int prime = 0x9E3779B1;
    int h(int s) => (s * prime) & 0x7fffffff;
    return AISeedBundle(
      perceptionSeed: turnSeed & 0x7fffffff,
      goalSeed: h(turnSeed),
      economySeed: h(h(turnSeed)),
      militarySeed: h(h(h(turnSeed))),
      diplomacySeed: h(h(h(h(turnSeed)))),
      researchSeed: h(h(h(h(h(turnSeed))))),
      tacticalSeed: h(h(h(h(h(h(turnSeed)))))),
      dialogueSeed: h(h(h(h(h(h(h(turnSeed))))))),
      agendaSeed: h(h(h(h(h(h(h(h(turnSeed)))))))),
    );
  }
}
