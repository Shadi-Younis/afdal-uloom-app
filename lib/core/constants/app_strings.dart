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

  static const retry = 'إعادة المحاولة';
  static const loading = 'جارٍ التحميل';

  // Login
  static const loginTitle = 'تسجيل الدخول';
  static const usernameLabel = 'اسم المستخدم';
  static const passwordLabel = 'كلمة السر';
  static const signIn = 'دخول';
  static const showPassword = 'إظهار كلمة السر';
  static const hidePassword = 'إخفاء كلمة السر';
  static const usernameRequired = 'أدخل اسم المستخدم';
  static const passwordRequired = 'أدخل كلمة السر';

  // Role home screens
  static const adminHomeTitle = 'لوحة المدير';
  static const teacherHomeTitle = 'لوحة المعلم';
  static const studentHomeTitle = 'لوحة الطالب';

  // Shared actions and states
  static const cancel = 'إلغاء';
  static const save = 'حفظ';
  static const add = 'إضافة';
  static const create = 'إنشاء';
  static const done = 'تم';
  static const copy = 'نسخ';
  static const copied = 'تم النسخ';
  static const disabledChip = 'موقوف';
  static const noResults = 'لا توجد نتائج';

  /// Between the items of a list in running text: "حلقة الفجر، حلقة المغرب".
  static const listSeparator = '، ';

  /// Between two details on one line: "S001 · حلقة الفجر".
  static const detailSeparator = ' · ';

  // Admin navigation
  static const adminNavHome = 'الرئيسية';
  static const adminNavHalaqat = 'الحلقات';
  static const adminNavTeachers = 'المعلمون';
  static const adminNavStudents = 'الطلاب';

  // Admin home
  static const adminWelcome = 'أهلاً بك';
  static const shortcutsTitle = 'اختصارات';
  static const addStudent = 'إضافة طالب';
  static const addTeacher = 'إضافة معلم';
  static const createHalaqa = 'إنشاء حلقة';

  // Form fields
  static const fullNameLabel = 'الاسم الكامل';
  static const studentCodeLabel = 'رقم الطالب';
  static const halaqaLabel = 'الحلقة';
  static const halaqaNameLabel = 'اسم الحلقة';
  static const teacherLabel = 'المعلم';
  static const generatePassword = 'توليد كلمة سر جديدة';

  // Form errors
  static const fullNameRequired = 'أدخل الاسم الكامل';
  static String fullNameLength(int min, int max) =>
      'الاسم من $min إلى $max حرفاً';
  static String usernameLength(int min, int max) =>
      'اسم المستخدم من $min إلى $max حرفاً';
  static const usernameInvalid =
      'استخدم أحرفاً إنجليزية صغيرة وأرقاماً و . _ - فقط';
  static String passwordLength(int min, int max) =>
      'كلمة السر من $min إلى $max حرفاً';
  static const studentCodeRequired = 'أدخل رقم الطالب';
  static const studentCodeInvalid =
      'رقم الطالب حرف S ثم 3 إلى 5 أرقام، مثل S013';
  static const halaqaRequired = 'اختر الحلقة';
  static const halaqaNameRequired = 'أدخل اسم الحلقة';
  static String halaqaNameTooLong(int max) =>
      'اسم الحلقة $max حرفاً على الأكثر';
  static const teacherRequired = 'اختر المعلم';

  // Halaqat
  static const newHalaqaTitle = 'حلقة جديدة';
  static const noHalaqat = 'لا توجد حلقات بعد';
  static String halaqaTeacher(String name) => 'المعلم: $name';
  static String studentCount(int count) => 'عدد الطلاب: $count';
  static const unknownTeacher = 'غير معروف';
  static const noActiveTeachers = 'لا يوجد معلم مفعّل. أضف معلماً أولاً.';
  static const halaqaCreated = 'تم إنشاء الحلقة';
  static const halaqaStudents = 'طلاب الحلقة';
  static const noStudentsInHalaqa = 'لا يوجد طلاب في هذه الحلقة بعد';
  static const renameHalaqa = 'تغيير الاسم';
  static const renameHalaqaTitle = 'تغيير اسم الحلقة';
  static const halaqaRenamed = 'تم تغيير اسم الحلقة';
  static const changeTeacher = 'تغيير المعلم';
  static const chooseTeacherTitle = 'اختر المعلم الجديد';
  static const noOtherTeacher = 'لا يوجد معلم مفعّل آخر.';
  static const changeTeacherConfirmTitle = 'تغيير معلم الحلقة';
  static String changeTeacherConfirm(String halaqa, String from, String to) =>
      'ستنتقل $halaqa من $from إلى $to.\n'
      'كل تسجيلات الحلقة الموجودة ستنتقل أيضاً إلى $to، '
      'ولن يراها $from بعد الآن.';
  static const teacherChanged = 'تم تغيير معلم الحلقة';

  // Teachers
  static const newTeacherTitle = 'معلم جديد';
  static const noTeachers = 'لا يوجد معلمون بعد';
  static const teacherHalaqat = 'حلقاته';
  static const withoutHalaqa = 'بلا حلقة';
  static const teacherCreated = 'تمت إضافة المعلم';

  // Students
  static const newStudentTitle = 'طالب جديد';
  static const noStudents = 'لا يوجد طلاب بعد';
  static const searchStudents = 'ابحث بالاسم أو رقم الطالب';
  static const allHalaqat = 'الكل';
  static const studentCreated = 'تمت إضافة الطالب';
  static const noFreeStudentCode =
      'استُخدمت كل الأرقام حتى S999، اكتب رقماً بنفسك';
  static const createHalaqaFirst = 'أنشئ حلقة أولاً لتضيف إليها الطلاب';
  static const createdAtLabel = 'تاريخ الإنشاء';
  static const statusLabel = 'الحالة';
  static const statusActive = 'مفعّل';
  static const statusDisabled = 'موقوف';
  static const recordingsTitle = 'التسجيلات';
  static const recordingsPlaceholder =
      'ستظهر هنا تسجيلات الطالب في تحديث قادم.';
  static const moveStudent = 'نقل إلى حلقة أخرى';
  static const chooseHalaqaTitle = 'اختر الحلقة الجديدة';
  static const noOtherHalaqa = 'لا توجد حلقة أخرى.';
  static const moveStudentConfirmTitle = 'نقل الطالب';
  static String moveStudentConfirm(String student, String from, String to) =>
      'سيُنقل $student من $from إلى $to.\n'
      'كل تسجيلاته ستنتقل معه، ويراها معلم $to.';
  static const studentMoved = 'تم نقل الطالب';

  // Accounts
  static const resetPassword = 'تغيير كلمة السر';
  static String resetPasswordTitle(String name) => 'كلمة سر جديدة لـ $name';
  static const passwordReset = 'تم تغيير كلمة السر';
  static const disableAccount = 'إيقاف الحساب';
  static const enableAccount = 'إعادة تفعيل الحساب';
  static String disableConfirm(String name) =>
      'لن يستطيع $name تسجيل الدخول حتى تعيد تفعيل حسابه. '
      'لن تُحذف أي بيانات.';
  static String enableConfirm(String name) =>
      'سيستطيع $name تسجيل الدخول من جديد.';
  static const accountDisabled = 'تم إيقاف الحساب';
  static const accountEnabled = 'تمت إعادة تفعيل الحساب';

  // Credentials sheet
  static const credentialsTitle = 'بيانات الدخول';
  static const credentialsWarning =
      'لن تظهر كلمة السر مرة أخرى. انسخها الآن وأرسلها لصاحب الحساب.';
  static const nameLabel = 'الاسم';
  static const roleStudent = 'الطالب';
  static const roleTeacher = 'المعلم';
  static const roleAdmin = 'المدير';

  /// The message the admin pastes into WhatsApp. [role] is [roleStudent],
  /// [roleTeacher] or [roleAdmin].
  static String credentialsMessage({
    required String role,
    required String name,
    required String username,
    required String password,
  }) =>
      'السلام عليكم، بيانات دخول $role $name إلى تطبيق دار أفضل العلوم:\n'
      '$usernameLabel: $username\n'
      '$passwordLabel: $password';

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
