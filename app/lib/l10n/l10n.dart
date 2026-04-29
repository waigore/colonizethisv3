import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// Returns app localizations with an English fallback for widget tests
/// that mount widgets without full MaterialApp localization delegates.
AppLocalizations appL10n(BuildContext context) {
  return AppLocalizations.of(context) ??
      lookupAppLocalizations(const Locale('en'));
}

