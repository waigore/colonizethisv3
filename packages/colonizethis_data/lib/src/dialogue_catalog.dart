// Dialogue key catalog for resolving DialogueEvent to localization keys.
// SPEC/ai/dialogue-and-mood.md: "Dialogue content (localized strings) lives in data assets;
// AI selects keys and context only." UI resolves (leaderId, category, situation, era, mood, variables)
// to a dialogue key and then to localized text.

/// Dialogue categories per SPEC/ai/dialogue-and-mood.md.
const List<String> kDialogueCategories = [
  'diplomatic',
  'reactive',
  'event',
  'agenda',
  'negotiation',
];

/// Dialogue eras for era-appropriate phrasing.
const List<String> kDialogueEras = [
  'discovery',
  'earlyModern',
  'imperial',
  'industrial',
];

/// Strategic AI agenda/comment cadence in turns (MVP).
///
/// SPEC/ai/dialogue-and-mood.md § When to emit:
/// Strategic AI may emit optional agenda-flavoured commentary and a matching
/// base PortraitMoodEvent once every [kDialogueTurnsBetweenComments] turns
/// for each AI leader, when `dialogueSeed % kDialogueTurnsBetweenComments == 0`.
const int kDialogueTurnsBetweenComments = 7;

/// Portrait mood values per spec (negotiation and base mood).
const List<String> kPortraitMoodValues = [
  'considering',
  'pleased',
  'gracious',
  'calculating',
  'skeptical',
  'impatient',
  'irritated',
  'dismissive',
];

/// Builds a stable dialogue key from event fields.
///
/// Format: `dialogue.{category}.{situation}.{era}` or, when [mood] is
/// provided (e.g. negotiation), `dialogue.{category}.{situation}.{era}.{mood}`.
/// UI can use this key to look up localized strings; [variables] from the
/// event are applied as template fill-ins (not part of the key).
///
/// Per SPEC/ai/dialogue-and-mood.md and SPEC/program/ai-events-and-dossier.md.
String dialogueKeyForEvent({
  required String category,
  required String situation,
  required String era,
  String? mood,
}) {
  final parts = ['dialogue', category, situation, era];
  if (mood != null && mood.isNotEmpty) {
    parts.add(mood);
  }
  return parts.join('.');
}
