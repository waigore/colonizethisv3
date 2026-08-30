/// Precomputed human draft review for `DLG60001`.
/// SPEC: SPEC/ui/components/staged-decree-review.md
library;

/// Player-facing decree family shown on next-turn confirmation.
enum StagedDecreeFamily {
  civilianWork,
  spyRelocate,
  armyMoves,
  fleet,
  trainingBuilds,
  labourRecruit,
  diplomacy,
  trade,
  research,
}

/// One plain-language staged row inside a family.
class StagedDecreeRow {
  const StagedDecreeRow({required this.id, required this.label});

  final String id;
  final String label;
}

/// One family with count > 0.
class StagedDecreeFamilyGroup {
  const StagedDecreeFamilyGroup({
    required this.family,
    required this.familyLabel,
    required this.rows,
  });

  final StagedDecreeFamily family;
  final String familyLabel;
  final List<StagedDecreeRow> rows;

  int get count => rows.length;
}

/// Snapshot passed into `DLG60001`. Empty when no listed decrees.
class StagedDecreeReview {
  const StagedDecreeReview({this.families = const []});

  final List<StagedDecreeFamilyGroup> families;

  bool get isEmpty => families.isEmpty;

  static const empty = StagedDecreeReview();
}
