import 'package:flutter/widgets.dart';

import 'app_localizations_contract.dart';
import 'app_localizations_en.dart';

/// Locale lookup for [AppLocalizations]. Kept in a separate library to avoid a
/// circular import between [app_localizations.dart] and [app_localizations_en.dart].
AppLocalizations lookupAppLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
