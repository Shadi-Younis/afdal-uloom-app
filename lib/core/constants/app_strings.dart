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
  static const errorNetwork = 'لا يوجد اتصال بالإنترنت';
  static const errorInvalidData = 'البيانات غير صحيحة.';
  static const errorInvalidCredentials = 'اسم المستخدم أو كلمة السر غير صحيحة';
  static const errorAccountDisabled = 'هذا الحساب موقوف، تواصل مع إدارة الدار';
  static const errorTooManyAttempts = 'محاولات كثيرة، حاول بعد قليل';
  static const errorNoRole = 'هذا الحساب غير مفعّل، تواصل مع إدارة الدار';
  static const errorUsernameTaken = 'اسم المستخدم مستخدم من قبل';
  static const errorStudentCodeTaken = 'رقم الطالب مستخدم من قبل';
  static const errorFailedPrecondition =
      'لا يمكن تنفيذ هذا الإجراء على هذا العنصر.';
  static const errorUnknown = 'حدث خطأ غير متوقع. حاول مرة أخرى.';
}
