import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_localizations_contract.dart';
import 'app_localizations_en.dart';

/// Stable entry points for `MaterialApp` / tests (Refs #2021 split).
abstract final class AppLocalizationsBinding {
  static const LocalizationsDelegate<AppLocalizations> delegate =
      CtAppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];
}

/// Locale dispatch for [AppLocalizations]. Lives outside [app_localizations_contract.dart]
/// so [app_localizations_en.dart] can depend on the contract without a library cycle.
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

/// [LocalizationsDelegate] for [AppLocalizations] (Refs #2021: split from gen-l10n output).
class CtAppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const CtAppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(CtAppLocalizationsDelegate old) => false;
}
