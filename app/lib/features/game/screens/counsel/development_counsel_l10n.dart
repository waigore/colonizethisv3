import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_logic/industry_counsel_api.dart';

String developmentCounselBriefForReason(
  AppLocalizations l10n,
  DevelopmentCounselReasonKey key,
) {
  return switch (key) {
    DevelopmentCounselReasonKey.coastalPort =>
      l10n.developmentCounsel_reason_coastalPort_brief,
    DevelopmentCounselReasonKey.resourceCoast =>
      l10n.developmentCounsel_reason_resourceCoast_brief,
    DevelopmentCounselReasonKey.newWorldCoast =>
      l10n.developmentCounsel_reason_newWorldCoast_brief,
    DevelopmentCounselReasonKey.overseasLinkage =>
      l10n.developmentCounsel_reason_overseasLinkage_brief,
  };
}

String developmentCounselTitleForRecommendation(
  AppLocalizations l10n,
  DevelopmentCounselRecommendation recommendation,
) {
  final location =
      recommendation.provinceDisplayName ?? recommendation.provinceId;
  if (location.isEmpty) {
    return l10n.developmentCounsel_title_buildPort;
  }
  return l10n.developmentCounsel_title_buildPortAt(location);
}
