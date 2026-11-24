import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter/widgets.dart' show LocalizationsDelegate;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:material_ui/material_ui.dart' show GlobalMaterialLocalizations;

import '../../l10n/app_localizations.dart';

/// Use this list instead of `AppLocalizations.localizationsDelegates`.
///
/// Since Flutter 3.47 the Material/Cupertino widgets live in the
/// `material_ui` / `cupertino_ui` packages, but `flutter gen-l10n` still
/// emits the old `flutter_localizations` delegates, which those widgets do
/// not find ("No MaterialLocalizations found"). Revisit when gen-l10n is
/// updated.
const List<LocalizationsDelegate<dynamic>> appLocalizationsDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
];
