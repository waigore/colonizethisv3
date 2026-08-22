/// First-order Favored Trading Partner copy (GAME30001 confirm + OVL90001).
/// SPEC/ui/diplomacy-panel.md § Confirm dialog; SPEC/game/world-market.md § FTP.
/// Refs #4586.
library;

/// Confirm body for offering Favored Trading Partner toward [target].
List<String> favoredTradingPartnerConfirmLines(String target) => [
  'Cost: No treasury charge.',
  'Effect: If $target accepts, you become Favored Trading Partners.',
  ...favoredTradingPartnerMatchingEffectLines(target),
];

/// Incoming-offer Accept meaning for court [offerer].
List<String> favoredTradingPartnerAcceptEffectLines(String offerer) => [
  'Effect: If you accept, you become Favored Trading Partners with $offerer.',
  ...favoredTradingPartnerMatchingEffectLines(offerer),
];

/// Same-rank matching, prices, and First right (shared by offer and answer).
List<String> favoredTradingPartnerMatchingEffectLines(String court) => [
  'Effect: When you and $court buy or sell the same good at the same bid rank, '
      'fills between you are preferred.',
  'Effect: Prices do not change.',
  'Effect: This does not beat First right of refusal.',
];

/// Incoming-offer Reject meaning for court [offerer].
String favoredTradingPartnerRejectEffectLine(String offerer) =>
    'Effect: You decline Favored Trading Partner with $offerer.';
