/// Player-facing Train {type} labels and gists (Refs #4752).
library;

import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'map_train_civilian_offer.dart';

String mapTrainCivilianLabel(AppLocalizations l10n, MapTrainCivilianKind kind) {
  switch (kind) {
    case MapTrainCivilianKind.explorer:
      return l10n.provinceOverlay_trainExplorer;
    case MapTrainCivilianKind.builder:
      return l10n.provinceOverlay_trainBuilder;
    case MapTrainCivilianKind.engineer:
      return l10n.provinceOverlay_trainEngineer;
    case MapTrainCivilianKind.merchant:
      return l10n.provinceOverlay_trainMerchant;
    case MapTrainCivilianKind.railBuilder:
      return l10n.provinceOverlay_trainRailBuilder;
  }
}

String mapTrainCivilianGist(AppLocalizations l10n, MapTrainCivilianKind kind) {
  switch (kind) {
    case MapTrainCivilianKind.explorer:
      return l10n.provinceOverlay_trainCivilianGistExplorer;
    case MapTrainCivilianKind.builder:
      return l10n.provinceOverlay_trainCivilianGistBuilder;
    case MapTrainCivilianKind.engineer:
      return l10n.provinceOverlay_trainCivilianGistEngineer;
    case MapTrainCivilianKind.merchant:
      return l10n.provinceOverlay_trainCivilianGistMerchant;
    case MapTrainCivilianKind.railBuilder:
      return l10n.provinceOverlay_trainCivilianGistRailBuilder;
  }
}
