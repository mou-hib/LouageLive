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
  String signUpWeakPassword(int min) {
    return 'كلمة المرور ضعيفة جدًا ($min أحرف على الأقل).';
  }

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
  String get chauffeurNoLouage =>
      'لا يوجد لواج مرتبط بحسابك، اتصل بعون المحطة.';

  @override
  String louageCapacite(int capacite) {
    String _temp0 = intl.Intl.pluralLogic(
      capacite,
      locale: localeName,
      other: '$capacite مقعدًا',
      few: '$capacite مقاعد',
      two: 'مقعدان',
      one: 'مقعد واحد',
    );
    return 'السعة: $_temp0';
  }

  @override
  String chauffeurInQueue(String station, String ville) {
    return 'أنت في الطابور: $station ← $ville';
  }

  @override
  String get scanStationQr => 'امسح رمز QR الخاص بالمحطة';

  @override
  String get scannerHint => 'ضع رمز QR الخاص بالمحطة داخل الإطار.';

  @override
  String get torchOn => 'تشغيل المصباح';

  @override
  String get torchOff => 'إطفاء المصباح';

  @override
  String get cameraPermissionDenied =>
      'اسمح بالوصول إلى الكاميرا لمسح رمز QR الخاص بالمحطة.';

  @override
  String get openSettings => 'فتح الإعدادات';

  @override
  String get cameraUnavailable => 'تعذّر استعمال الكاميرا على هذا الجهاز.';

  @override
  String get chooseLine => 'اختر خطّك';

  @override
  String get noActiveLine => 'لا يوجد خط نشط في هذه المحطة.';

  @override
  String tarifDt(String tarif) {
    return '$tarif د.ت';
  }

  @override
  String joinQueueConfirm(String station, String ville) {
    return 'الانضمام إلى طابور $station ← $ville؟';
  }

  @override
  String get cancel => 'إلغاء';

  @override
  String get joinQueue => 'انضمام';

  @override
  String get joinedQueue => 'انضممت إلى الطابور.';

  @override
  String get fileErrAccesRefuse => 'يمكن للسائقين فقط الانضمام إلى الطابور.';

  @override
  String get fileErrAucunLouage => 'لا يوجد لواج نشط مرتبط بحسابك.';

  @override
  String get fileErrQrInvalide =>
      'رمز QR غير معروف. امسح رمز QR الخاص بالمحطة.';

  @override
  String get fileErrDejaEnFile => 'لواجك موجود بالفعل في طابور.';

  @override
  String get fileErrReservationDejaEnCours => 'لديك حجز قيد الانتظار بالفعل.';

  @override
  String get fileErrLouagePasEnTete =>
      'لا يمكن الحجز إلا في اللواج الذي في مقدمة الطابور.';

  @override
  String get fileErrLouagePasComplet => 'يجب أن يكون اللواج ممتلئًا للانطلاق.';

  @override
  String get fileErrReservationEnAttente => 'توجد حجوزات لم يتم مسحها بعد.';

  @override
  String fileErrReservationEnAttenteJusqua(DateTime heure) {
    final intl.DateFormat heureDateFormat = intl.DateFormat.Hm(localeName);
    final String heureString = heureDateFormat.format(heure);

    return 'يوجد حجز لم يتم مسحه بعد. ينتهي على الساعة ⁦$heureString⁩.';
  }

  @override
  String get fileErrPlacesSousReservations =>
      'غير ممكن: عدد المقاعد أقل من عدد الحجوزات.';

  @override
  String get notifTourDeRemplir => 'حان دورك: لواجك في مقدمة الطابور.';

  @override
  String get notifReservationExpiree => 'انتهت صلاحية حجزك قبل الصعود.';

  @override
  String get notifReservationAnnulee => 'تم إلغاء حجزك: غادر اللواج الطابور.';

  @override
  String get notifReservationAnnuleeAgent =>
      'تم إلغاء حجزك: سمح العون بانطلاق اللواج.';

  @override
  String get notifInconnue => 'إشعار جديد.';

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

  @override
  String seatsOccupiedA11y(int occupied, int capacity) {
    return 'المقاعد المشغولة: $occupied من $capacity';
  }

  @override
  String get statusEnAttente => 'في الانتظار';

  @override
  String get statusEnRemplissage => 'قيد التعبئة';

  @override
  String get statusPresqueComplet => 'شبه ممتلئ';

  @override
  String get statusComplet => 'ممتلئ';

  @override
  String get statusParti => 'انطلق';

  @override
  String get statusRetire => 'سُحب';

  @override
  String get reservationEnAttente => 'في الانتظار';

  @override
  String get reservationConfirmee => 'مؤكَّد';

  @override
  String get reservationAnnulee => 'ملغى';

  @override
  String get reservationExpiree => 'منتهي الصلاحية';

  @override
  String get queueHead => 'في رأس الطابور';

  @override
  String queueRankA11y(int rank) {
    return 'الرتبة $rank';
  }

  @override
  String get etaLabel => 'الانطلاق المتوقع';

  @override
  String get fareLabel => 'التعريفة';

  @override
  String get liveNow => 'مباشر';

  @override
  String liveUpdatedSecondsAgo(int seconds) {
    return 'آخر تحديث منذ $seconds ث';
  }

  @override
  String liveUpdatedMinutesAgo(int minutes) {
    return 'آخر تحديث منذ $minutes د';
  }

  @override
  String get liveOffline => 'غير متصل';

  @override
  String get loading => 'جارٍ التحميل…';

  @override
  String get seatStepperRemove => 'إزالة مقعد';

  @override
  String get seatStepperAdd => 'إضافة مقعد';

  @override
  String seatStepperValueA11y(int value) {
    return 'المقاعد: $value';
  }

  @override
  String get galleryTitle => 'معرض المكوّنات';

  @override
  String get gallerySubtitle => 'لواج أبيض';

  @override
  String get galleryOpen => 'فتح المعرض';

  @override
  String get galleryDarkMode => 'الوضع الداكن';

  @override
  String get galleryArabic => 'العربية (من اليمين لليسار)';

  @override
  String get galleryReduceMotion => 'بدون حركة';

  @override
  String get galleryConnected => 'متصل';

  @override
  String get galleryLoading => 'تحميل';

  @override
  String get galleryButtons => 'الأزرار';

  @override
  String get gallerySeats => 'المقاعد';

  @override
  String get galleryChips => 'الحالات';

  @override
  String get galleryCards => 'بطاقات اللواج';

  @override
  String get galleryBanners => 'الشرائط';

  @override
  String get galleryFields => 'الحقول';

  @override
  String get galleryStepper => 'عدّاد السائق';

  @override
  String get galleryStatusView => 'شاشة الحالة';

  @override
  String get gallerySkeleton => 'تحميل (هيكل)';

  @override
  String get galleryTypography => 'الخطوط';

  @override
  String get galleryAppBar => 'شريط التطبيق';

  @override
  String get galleryLive => 'الوقت الحقيقي';

  @override
  String get galleryPrimary => 'رئيسي';

  @override
  String get gallerySecondary => 'ثانوي';

  @override
  String get galleryOutline => 'محدَّد';

  @override
  String get galleryText => 'نص';

  @override
  String get galleryDestructive => 'حذف';

  @override
  String get galleryDriver => 'بدء الانطلاق';

  @override
  String get galleryRoute => 'باب سعدون ← سوسة';

  @override
  String get galleryEta => '≈ 10 د';

  @override
  String get galleryBannerOffline =>
      'لا يوجد اتصال. قد تكون المقاعد المعروضة قديمة.';

  @override
  String get galleryBannerError => 'تعذّر تحديث الطابور.';

  @override
  String get galleryBannerWarn => 'بقي مقعدان فقط في هذا اللواج.';

  @override
  String get galleryBannerOk => 'تم تأكيد الحجز.';

  @override
  String get galleryStatusTitle => 'لا يوجد لواج في الطابور';

  @override
  String get galleryStatusMessage =>
      'ستظهر اللواجات هنا بمجرد انضمام سائق إلى الطابور.';

  @override
  String get splashTagline => 'اللواج مباشرةً';

  @override
  String get otherLanguageName => 'Français';

  @override
  String get loginSubtitle => 'تابع لواجك مباشرةً.';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get forgotPasswordInfo =>
      'لإعادة تعيين كلمة المرور، اتصل بعون المحطة أو بالمشرف.';

  @override
  String get signingIn => 'جارٍ الدخول…';

  @override
  String get noAccountYet => 'ليس لديك حساب؟';

  @override
  String get createTravelerAccount => 'أنشئ حساب مسافر';

  @override
  String get loginOfflineBanner =>
      'لا يوجد اتصال بالإنترنت. يمكنك الدخول عند عودة الشبكة.';

  @override
  String get loginFieldCheckCredentials =>
      'تحقّق من البريد الإلكتروني وكلمة المرور.';

  @override
  String get loginFieldEmailNotConfirmed =>
      'افتح الرابط الذي وصلك بالبريد لتأكيد هذا العنوان.';

  @override
  String get createMyAccount => 'إنشاء حسابي';

  @override
  String get alreadyHaveAccountQuestion => 'لديك حساب؟';

  @override
  String get back => 'رجوع';

  @override
  String get profileErrorTitle => 'الملف الشخصي غير موجود';

  @override
  String get changePasswordTitle => 'كلمة مرور جديدة';

  @override
  String signedInAs(String email) {
    return 'متصل باسم $email';
  }

  @override
  String get changePasswordTempBanner =>
      'أُنشئ حسابك بكلمة مرور مؤقتة. اختر كلمة مرور جديدة للمتابعة.';

  @override
  String get newPasswordLabel => 'كلمة المرور الجديدة';

  @override
  String get confirmShort => 'تأكيد';

  @override
  String ruleMinLength(int min) {
    return '$min أحرف على الأقل';
  }

  @override
  String get ruleDigit => 'رقم واحد على الأقل';

  @override
  String get ruleMatch => 'كلمتا المرور متطابقتان';

  @override
  String ruleMetA11y(String rule) {
    return '$rule: مستوفى';
  }

  @override
  String ruleNotMetA11y(String rule) {
    return '$rule: غير مستوفى';
  }

  @override
  String get saveAndContinue => 'حفظ ومتابعة';

  @override
  String get saving => 'جارٍ الحفظ…';

  @override
  String get changePwdErrWeak => 'كلمة المرور ضعيفة أو شائعة جدًا. اختر غيرها.';

  @override
  String get changePwdErrSame =>
      'يجب أن تختلف كلمة المرور الجديدة عن كلمة المرور المؤقتة.';

  @override
  String get changePwdErrSession =>
      'انتهت جلستك. سجّل الدخول من جديد ثم أعد المحاولة.';
}
