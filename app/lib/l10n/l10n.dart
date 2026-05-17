import 'package:flutter/widgets.dart';

export 'app_localizations_contract.dart';
export 'app_localizations_delegate.dart';

import 'app_localizations_contract.dart';
import 'app_localizations_delegate.dart';

/// Returns app localizations with an English fallback for widget tests
/// that mount widgets without full MaterialApp localization delegates.
AppLocalizations appL10n(BuildContext context) {
  return AppLocalizations.of(context) ??
      lookupAppLocalizations(const Locale('en'));
}
