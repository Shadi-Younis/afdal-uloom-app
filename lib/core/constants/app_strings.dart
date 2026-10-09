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
  static const back = 'رجوع';

  // Ornamental texts (Amiri).
  static const basmala = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';
  static const hadith = '«خَيْرُكُمْ مَنْ تَعَلَّمَ الْقُرْآنَ وَعَلَّمَهُ»';
  static const salam = 'السلام عليكم ورحمة الله';

  /// Android back on a home screen; a second press within 2 s exits.
  static const pressBackAgainToExit = 'اضغط مرة أخرى للخروج';

  // Hijri date: "٢٧ ربيع الآخر ١٤٤٨ هـ · الجمعة".
  static const hijriMonths = [
    'محرم',
    'صفر',
    'ربيع الأول',
    'ربيع الآخر',
    'جمادى الأولى',
    'جمادى الآخرة',
    'رجب',
    'شعبان',
    'رمضان',
    'شوال',
    'ذو القعدة',
    'ذو الحجة',
  ];
  static const hijriEra = 'هـ';

  /// Monday first, like DateTime.weekday (1 = Monday).
  static const weekdays = [
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];

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
  static const teacherComingSoon =
      'ستظهر هنا حلقاتك وتسجيلات طلابك قريباً، إن شاء الله.';
  static const studentComingSoon =
      'ستظهر هنا تسجيلاتك وملاحظات معلمك قريباً، إن شاء الله.';

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
  static String studentCount(String count) => 'عدد الطلاب: $count';
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
  static const recordingsTitle = 'التسجيلات';
  static const studentInfo = 'بيانات الطالب';
  static const teacherInfo = 'بيانات المعلم';
  static const noRecordings = 'لا توجد تسجيلات بعد';
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

  // Deleting
  static const ok = 'حسناً';
  static const dangerZone = 'الحذف';
  static const deleteHalaqa = 'حذف الحلقة';
  static const deleteHalaqaHint = 'تُحذف الحلقة فقط إذا لم يبقَ فيها طلاب.';
  static String deleteHalaqaConfirm(String name) =>
      'ستُحذف $name نهائياً. لا يمكن التراجع عن ذلك.';
  static const halaqaDeleted = 'تم حذف الحلقة';
  static const cannotDeleteHalaqa = 'لا يمكن حذف الحلقة';

  /// [count] arrives in Arabic-Indic digits.
  static String halaqaHasStudents(String count) =>
      'انقل طلاب الحلقة أولاً إلى حلقة أخرى، ومنهم الموقوفون، ثم احذفها.\n'
      'عدد طلابها الآن: $count';
  static const showStudents = 'عرض الطلاب';
  static const deleteTeacher = 'حذف المعلم';
  static const deleteTeacherHint = 'يُحذف المعلم فقط إذا لم تبقَ له حلقات.';
  static String deleteTeacherConfirm(String name) =>
      'سيُحذف حساب $name نهائياً ولن يستطيع الدخول. '
      'تبقى ملاحظاته على التسجيلات باسم «$formerTeacher». '
      'لا يمكن التراجع عن ذلك.';
  static const teacherDeleted = 'تم حذف المعلم';
  static const cannotDeleteTeacher = 'لا يمكن حذف المعلم';
  static const teacherHasHalaqat =
      'انقل حلقات المعلم لمعلم آخر أولاً: افتح كل حلقة واضغط «$changeTeacher».';
  static const deleteStudent = 'حذف نهائي';
  static const deleteStudentHint =
      'الإيقاف يمنع الدخول ويحفظ كل البيانات، ويمكن التراجع عنه.\n'
      'الحذف النهائي يحذف الحساب وكل تسجيلاته وملاحظاتها، '
      'ولا يمكن التراجع عنه.';
  static String deleteStudentTitle(String name) => 'حذف $name نهائياً';
  static const deleteStudentWarning =
      'سيُحذف حساب الطالب وكل تسجيلاته وملفاتها وملاحظات المعلم عليها. '
      'لا يمكن التراجع عن ذلك.';

  /// [count] arrives in Arabic-Indic digits.
  static String recordingsToDelete(String count) =>
      'عدد التسجيلات التي ستُحذف: $count';
  static String typeCodeToConfirm(String code) =>
      'للتأكيد، اكتب رقم الطالب: $code';
  static const studentDeleted = 'تم حذف الطالب نهائياً';

  /// The author of a note whose teacher account was deleted.
  static const formerTeacher = 'معلم سابق';

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

  // Recording screen
  static const recordingScreenTitle = 'التسجيل';
  static String recordingOf(String student) => 'تسجيل $student';
  static String surahName(String name) => 'سورة $name';
  static String ayahRange(String from, String to) => 'الآيات $from–$to';
  static String oneAyah(String ayah) => 'الآية $ayah';
  static const typeOfficial = 'رسمي';
  static const typePractice = 'تدريب';
  static const recordedAtLabel = 'تاريخ التسجيل';
  static const uploadedByLabel = 'رُفع بواسطة';
  static const unreadFeedback = 'ملاحظة جديدة لم يقرأها الطالب';
  static const feedbackTitle = 'ملاحظات المعلم';
  static const noFeedback = 'لا توجد ملاحظات بعد';

  /// A note about a moment of the recording, e.g. "عند ٠١:٢٣".
  static String atTime(String clock) => 'عند $clock';
  static String ratingOf(String stars, String max) => 'التقييم: $stars من $max';

  // Recording player
  static const playerLoading = 'جارٍ تحميل التسجيل';
  static const play = 'تشغيل';
  static const pause = 'إيقاف مؤقت';
  static String skipBack(String seconds) => 'رجوع $seconds ثوانٍ';
  static String skipForward(String seconds) => 'تقديم $seconds ثوانٍ';
  static const playbackPosition = 'موضع التشغيل';
  static const playbackSpeed = 'سرعة التشغيل';

  // Recording titles. The numbers arrive already in Arabic-Indic digits.
  static String recordingTitle(String surah, String from, String to) =>
      '$surah: الآيات $from–$to';
  static String recordingTitleOneAyah(String surah, String ayah) =>
      '$surah: الآية $ayah';

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
  static const errorHalaqaHasStudents = 'انقل طلاب الحلقة أولاً';
  static const errorHalaqaHasRecordings =
      'ما زالت في الحلقة تسجيلات، انقل طلابها أولاً';
  static const errorTeacherOwnsHalaqat = 'انقل حلقات المعلم لمعلم آخر أولاً';
  static const errorLastAdmin =
      'لا يمكن إيقاف آخر مدير مفعّل. أضف مديراً آخر أولاً.';
  static const errorWrongPassword = 'كلمة السر الحالية غير صحيحة';
  static const errorWeakPassword = 'كلمة السر الجديدة ضعيفة، اختر أطول منها';

  /// The limit is AudioFormats.maxUploadBytes (100 MiB).
  static const errorFileTooLarge = 'الملف أكبر من ١٠٠ ميغابايت.';
  static const errorUnsupportedFile = 'نوع الملف غير مدعوم. اختر ملفاً صوتياً.';
  static const errorUploadCancelled = 'تم إلغاء الرفع.';
  static const errorUnknown = 'حدث خطأ غير متوقع. حاول مرة أخرى.';
}
