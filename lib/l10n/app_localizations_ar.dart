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
  String get emailInvalid => 'عنوان البريد الإلكتروني غير صالح.';

  @override
  String get loginEmailNotConfirmed => 'عنوان البريد الإلكتروني غير مؤكَّد.';

  @override
  String get loginTooManyAttempts =>
      'محاولات كثيرة جدًا، أعد المحاولة بعد قليل.';

  @override
  String get loginNetworkError => 'لا يوجد اتصال بالإنترنت.';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get noAccountCreateOne => 'ليس لديك حساب؟ أنشئ حسابًا';

  @override
  String get staffAccountNote =>
      'السائقون وأعوان المحطات: يُنشئ المسؤول حسابكم.';

  @override
  String get alreadyHaveAccount => 'لديك حساب؟ سجّل الدخول';

  @override
  String get firstName => 'الاسم';

  @override
  String get lastName => 'اللقب';

  @override
  String get phone => 'الهاتف';

  @override
  String get phoneHint => 'مثال: 98 123 456';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get showPassword => 'إظهار كلمة المرور';

  @override
  String get hidePassword => 'إخفاء كلمة المرور';

  @override
  String get phoneInvalid => 'رقم غير صالح: 8 أرقام، و‎+216 اختياري.';

  @override
  String passwordTooShort(int min) {
    return '$min أحرف على الأقل.';
  }

  @override
  String get passwordsDontMatch => 'كلمتا المرور غير متطابقتين.';

  @override
  String get signUpEmailExists => 'يوجد حساب بهذا البريد الإلكتروني.';

  @override
  String get signUpWeakPassword => 'كلمة المرور ضعيفة جدًا (6 أحرف على الأقل).';

  @override
  String get signUpTooManyAttempts =>
      'محاولات كثيرة جدًا، أعد المحاولة لاحقًا.';

  @override
  String get checkEmailTitle => 'تحقّق من بريدك الإلكتروني';

  @override
  String get checkEmailSentTo => 'أرسلنا رابط تأكيد إلى:';

  @override
  String get checkEmailNextStep =>
      'افتح هذا الرابط لتفعيل حسابك، ثم سجّل الدخول.';

  @override
  String get backToLogin => 'العودة إلى تسجيل الدخول';

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
