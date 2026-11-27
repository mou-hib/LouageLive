import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Adds the bundled Rubik font's SIL Open Font License to the app's
/// licence page (showLicensePage), as the OFL asks.
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(const ['Rubik'], text);
  });
}
