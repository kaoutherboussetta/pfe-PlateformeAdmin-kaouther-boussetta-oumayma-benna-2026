import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../providers/locale_provider.dart';
import 'app_strings.dart';

extension AppL10n on BuildContext {
  /// Textes UI selon la langue choisie (rebuild si la langue change).
  ///
  /// À utiliser uniquement dans [State.build] (ou équivalent). Dans un callback
  /// (`onPressed`, après `async`, etc.), utiliser [stringsRead] ou
  /// `read<LocaleProvider>().strings`.
  AppStrings get strings => watch<LocaleProvider>().strings;

  /// Mêmes textes que [strings], sans abonnement — pour callbacks hors [build].
  AppStrings get stringsRead => read<LocaleProvider>().strings;
}
