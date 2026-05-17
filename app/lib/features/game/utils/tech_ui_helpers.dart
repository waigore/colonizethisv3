import '../../../l10n/l10n.dart';

String eraRoman(int era) {
  const romans = ['I', 'II', 'III', 'IV'];
  return era >= 1 && era <= romans.length ? romans[era - 1] : '$era';
}

String techCategoryLabelL10n(AppLocalizations l10n, String category) {
  return switch (category) {
    'gathering' => l10n.techTree_categoryGathering,
    'transport' => l10n.techTree_categoryTransport,
    'labour' => l10n.techTree_categoryLabour,
    'civilian' => l10n.techTree_categoryCivilian,
    'diplomacy' => l10n.techTree_categoryDiplomacy,
    'naval' => l10n.techTree_categoryNaval,
    'military' => l10n.techTree_categoryMilitary,
    'new-world' => l10n.techTree_categoryNewWorld,
    _ => category,
  };
}
