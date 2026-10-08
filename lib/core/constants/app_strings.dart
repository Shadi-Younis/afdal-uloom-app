/// Every user-facing text in the app. The UI is Arabic only.
abstract final class AppStrings {
  /// The only UI language.
  static const languageCode = 'ar';

  static const appTitle = 'أفضل العلوم';
  static const schoolLogoLabel = 'شعار دار أفضل العلوم';
  static const logout = 'تسجيل الخروج';

  /// Debug-only ribbon shown when a debug build talks to the real project;
  /// developers read it, so it is not translated.
  static const prodBanner = 'PROD';

  // Login
  static const loginTitle = 'تسجيل الدخول';
  // TODO: remove the role shortcuts after auth (phase 2.4).
  static const loginAsAdmin = 'دخول كمدير';
  static const loginAsTeacher = 'دخول كمعلم';
  static const loginAsStudent = 'دخول كطالب';

  // Role home screens
  static const adminHomeTitle = 'لوحة المدير';
  static const teacherHomeTitle = 'لوحة المعلم';
  static const studentHomeTitle = 'لوحة الطالب';

  // Errors, one per AppErrorCode
  static const errorPermissionDenied = 'ليست لديك صلاحية لهذا الإجراء.';
  static const errorNotFound = 'العنصر المطلوب غير موجود.';
  static const errorNetwork =
      'تعذّر الاتصال. تحقّق من الإنترنت وحاول مرة أخرى.';
  static const errorInvalidData = 'البيانات غير صحيحة.';
  static const errorUnknown = 'حدث خطأ غير متوقع. حاول مرة أخرى.';
}
