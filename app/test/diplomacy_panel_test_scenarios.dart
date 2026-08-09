// Diplomacy panel mode-bar filter scenario table (Refs #4269 Slice E).
// Lives outside `app/test/support/` so scenario tables do not count toward the
// support LOC ratchet.

/// Mode-bar tap scenario: label to tap and sections that must be hidden after.
class DiplomacyModeBarFilterScenario {
  const DiplomacyModeBarFilterScenario({
    required this.filterLabel,
    required this.hiddenSectionHeadings,
    this.visibleSectionHeadings = const [],
  });

  final String filterLabel;
  final List<String> hiddenSectionHeadings;
  final List<String> visibleSectionHeadings;
}

const diplomacyModeBarFilterScenarios = <DiplomacyModeBarFilterScenario>[
  DiplomacyModeBarFilterScenario(
    filterLabel: 'Great Powers only',
    hiddenSectionHeadings: ['Minor Nations', 'Tribes'],
    visibleSectionHeadings: ['Great Powers'],
  ),
  DiplomacyModeBarFilterScenario(
    filterLabel: 'Minors only',
    hiddenSectionHeadings: ['Great Powers'],
  ),
];

const diplomacyModeBarFilterLabels = <String>[
  'All',
  'Great Powers only',
  'Minors only',
];
