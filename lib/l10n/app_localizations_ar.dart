// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'لواج لايف';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get signIn => 'دخول';

  @override
  String get voyageurHomeTitle => 'فضاء المسافر';

  @override
  String get chauffeurHomeTitle => 'فضاء السائق';

  @override
  String get agentHomeTitle => 'فضاء عون المحطة';

  @override
  String get adminHomeTitle => 'الإدارة';

  @override
  String get changeLanguage => 'تغيير اللغة';

  @override
  String get genericError => 'حدث خطأ. يرجى المحاولة مرة أخرى.';

  @override
  String get loginFailed => 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';

  @override
  String get fieldRequired => 'هذا الحقل إجباري.';

  @override
  String get comingSoon => 'ستتوفر الميزات في المراحل القادمة.';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get profileErrorGeneric =>
      'تعذّر تحميل ملفك الشخصي. أعد المحاولة أو اتصل بالمسؤول.';

  @override
  String get profileErrorNetwork =>
      'تعذّر تحميل ملفك الشخصي. تحقّق من اتصالك بالإنترنت.';

  @override
  String get configMissing =>
      'إعدادات Supabase مفقودة. شغّل التطبيق باستعمال ‎--dart-define-from-file=config/env.json (راجع README).';
}
