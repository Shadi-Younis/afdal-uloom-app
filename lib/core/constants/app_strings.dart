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

  /// After the app signed out an account that was deleted or disabled
  /// while it was signed in.
  static const accountNoLongerActive =
      'لم يعد هذا الحساب فعّالاً. تواصل مع إدارة الدار.';

  // Student home
  static const myRecordings = 'تسجيلاتي';
  static const newNotes = 'ملاحظات جديدة';
  static const myPracticeThisWeek = 'تدريباتي هذا الأسبوع';
  static const recordPractice = 'سجّل تدريباً';
  static const filterAll = 'الكل';
  static const recordingsFilter = 'نوع التسجيلات';
  static const noStudentRecordings =
      'لا توجد تسجيلات بعد. سيظهر هنا ما يرفعه الشيخ وتدريباتك.';
  static const noRecordingsOfType = 'لا توجد تسجيلات من هذا النوع';

  /// The teacher as students see him: «الشيخ», or «الشيخ محمود» once
  /// his name is known (SheikhName).
  static const sheikh = 'الشيخ';
  static String sheikhNamed(String name) => '$sheikh $name';

  // Practice recorder (the student)
  static const practiceTitle = 'تسجيل تدريب';
  static const practiceWhat = 'ماذا ستتلو؟';
  static const recorderReady = 'اضغط الزر وابدأ التلاوة';
  static const recordingNow = 'جارٍ التسجيل';
  static const recordingPaused = 'التسجيل متوقف مؤقتاً';
  static const startRecording = 'ابدأ التسجيل';
  static const pauseRecording = 'إيقاف مؤقت';
  static const resumeRecording = 'متابعة التسجيل';
  static const stopRecording = 'إنهاء التسجيل';
  static const inputLevel = 'مستوى الصوت';

  /// [minutes] arrives in Arabic-Indic digits.
  static String recordingNearLimit(String minutes) =>
      'اقترب التسجيل من حدّه ($minutes دقيقة)، وسيتوقف تلقائياً عنده.';

  /// [minutes] arrives in Arabic-Indic digits.
  static String recordingLimitReached(String minutes) =>
      'وصل التسجيل إلى حدّه ($minutes دقيقة) فتوقف. استمع إليه ثم أرسله.';
  static const yourRecording = 'تسجيلك';
  static const recordAgain = 'إعادة التسجيل';
  static const recordAgainMessage = 'سيُحذف هذا التسجيل ولن يُرسل للشيخ.';
  static const sendToSheikh = 'إرسال للشيخ';
  static const pickExistingFile = 'اختيار ملف';
  static const orPickFile = 'أو أرسل ملفاً صوتياً موجوداً على جهازك';
  static const removePickedFile = 'إلغاء اختيار الملف';
  static const completeTheAyat = 'اختر السورة والآيات أولاً';
  static const practiceSent = 'وصل تدريبك إلى الشيخ';
  static const sending = 'جارٍ الإرسال';
  static const microphoneDenied =
      'لا يستطيع التطبيق استخدام الميكروفون. '
      'اسمح له بالميكروفون من إعدادات الهاتف، ثم عد إلى هنا.';
  static const microphoneDeniedWeb =
      'المتصفح منع الميكروفون عن هذا الموقع. '
      'اسمح به من إعدادات الموقع (رمز القفل بجانب العنوان)، ثم أعد المحاولة.';
  static const openSettings = 'فتح الإعدادات';
  static const leaveRecordingTitle = 'التدريب لم يُرسل';
  static const leaveRecordingMessage =
      'إذا خرجت الآن يضيع هذا التسجيل ولا يصل إلى الشيخ.';
  static const leaveSendingMessage =
      'إذا خرجت الآن يتوقف الإرسال ولا يصل التدريب إلى الشيخ.';

  // Deleting a practice recording (the student)
  static const deletePractice = 'حذف التدريب';
  static const deletePracticeMessage =
      'سيُحذف هذا التدريب نهائياً ولن يصل إلى الشيخ.';
  static const practiceDeleted = 'تم حذف التدريب';

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

  /// A details page whose item was deleted elsewhere while it was open.
  static const itemDeleted = 'تم حذف هذا العنصر';

  /// Between the items of a list in running text: "حلقة الفجر، حلقة المغرب".
  static const listSeparator = '، ';

  /// Between two details on one line: "S001 · حلقة الفجر".
  static const detailSeparator = ' · ';

  // Teacher home and pages
  static const myStudents = 'طلابي';
  static const thisWeekRecordings = 'تسجيلات هذا الأسبوع';
  static const pendingReview = 'بانتظار المراجعة';
  static const myHalaqat = 'حلقاتي';
  static const noTeacherHalaqat = 'لا توجد لك حلقة بعد. تواصل مع إدارة الدار.';
  static const uploadRecordings = 'رفع تسجيلات';
  static const uploadForStudent = 'رفع تسجيل لهذا الطالب';
  static const noPendingReview =
      'لا توجد تسجيلات بانتظار المراجعة. بارك الله فيك.';

  // Upload page (studio recordings)
  static const pickFiles = 'اختيار ملفات';
  static const uploadHint =
      'اختر ملفات التسجيل التي صدّرتها من Studio One. '
      'اسم الملف مثل S014_002_001-020.mp3 يملأ الطالب والسورة والآيات.';
  static const dropHint = 'أو اسحب الملفات وأفلتها هنا';
  static const dropNow = 'أفلت الملفات هنا';
  static const studentFieldLabel = 'الطالب';
  static const surahLabel = 'السورة';
  static const searchSurah = 'ابحث باسم السورة أو رقمها';
  static const ayahFromLabel = 'من آية';
  static const ayahToLabel = 'إلى آية';
  static const ayatNotInSurah = 'الآيات ليست في هذه السورة';
  static const completeTheRow = 'أكمل بيانات هذا الملف';
  static const uploadAll = 'رفع الكل';
  static const removeFile = 'إزالة الملف';
  static const openRecording = 'فتح التسجيل';
  static const uploadWaiting = 'في الانتظار';
  static const uploadDone = 'تم الرفع';
  static const uploadCancelled = 'أُلغي الرفع';
  static const studentNotYours = 'اختر طالباً من القائمة';

  /// [percent] arrives in Arabic-Indic digits.
  static String uploading(String percent) => 'جارٍ الرفع… $percent٪';

  // Two-file mode of the upload page (Task 11).
  static const sourceOneFile = 'ملف واحد (يسار/يمين)';
  static const sourceTwoFiles = 'ملفين: الطالب + الشيخ';
  static const stemStudent = 'صوت الطالب';
  static const stemSheikh = 'صوت الشيخ';
  static const swapStems = 'تبديل';
  static const pickStem = 'اختيار ملف';
  static const dropStem = 'اسحب الملف هنا';
  static const noStemYet = 'لم يُختر ملف بعد';
  static const stemsMissing = 'أضف صوت الطالب وصوت الشيخ';

  /// One file of two while uploading: [stem] is [stemStudent] or
  /// [stemSheikh]; [percent] arrives in Arabic-Indic digits.
  static String stemUploading(String stem, String percent) =>
      '$stem: $percent٪';

  /// A file's size and length, e.g. "٣٫٢ ميغابايت · ٠١:٠١"; both arrive
  /// formatted.
  static String sizeAndLength(String size, String length) => '$size · $length';

  /// [megabytes] arrives in Arabic-Indic digits.
  static String fileSize(String megabytes) => '$megabytes ميغابايت';

  /// [done] and [total] arrive in Arabic-Indic digits.
  static String uploadedOf(String done, String total) =>
      'تم رفع $done من $total';
  static const leaveUploadTitle = 'الرفع لم ينتهِ';
  static const leaveUploadMessage =
      'إذا خرجت الآن يتوقف رفع الملف الحالي ولا تُرفع الملفات الباقية.';
  static const leave = 'خروج';

  // Admin navigation
  static const adminNavHome = 'الرئيسية';
  static const adminNavHalaqat = 'الحلقات';
  static const adminNavTeachers = 'المعلمين';
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

  // My account
  static const myAccount = 'حسابي';
  static const myInfo = 'بياناتي';
  static const roleLabel = 'الدور';
  static const roleNameAdmin = 'مدير';
  static const roleNameTeacher = 'معلم';
  static const roleNameStudent = 'طالب';
  static const currentPasswordLabel = 'كلمة السر الحالية';
  static const newPasswordLabel = 'كلمة السر الجديدة';
  static const confirmPasswordLabel = 'تأكيد كلمة السر الجديدة';
  static const currentPasswordRequired = 'أدخل كلمة السر الحالية';
  static const passwordsDontMatch = 'كلمتا السر غير متطابقتين';
  static const changePasswordHint =
      'تبقى مسجّلاً على هذا الجهاز، وتُغلق جلساتك على الأجهزة الأخرى.';

  // Editing accounts
  static const editProfile = 'تعديل البيانات';
  static String editProfileTitle(String name) => 'تعديل بيانات $name';
  static const usernameChangeHint =
      'تغيير اسم المستخدم يغيّر اسم الدخول. أخبر صاحب الحساب بالاسم الجديد.';
  static const profileUpdated = 'تم حفظ التعديلات';

  // Admins
  static const adminsTitle = 'المدراء';
  static const addAdmin = 'إضافة مدير';
  static const newAdminTitle = 'مدير جديد';
  static const adminCreated = 'تمت إضافة المدير';
  static const adminInfo = 'بيانات المدير';
  static const adminsHint =
      'مدير ثانٍ احتياطي يستطيع الدخول إذا تعذّر على المدير الأول.';

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
  static const feedbackTitle = 'ملاحظات الشيخ';
  static const noFeedback = 'لا توجد ملاحظات بعد';

  // The sheikh's voice markers and notes (Task 09).
  static const voiceNote = 'ملاحظة صوتية من الشيخ';

  /// A span of the recording, e.g. "٠١:٢٣–٠١:٣١"; the clocks arrive
  /// formatted.
  static String timeRange(String from, String to) => '$from–$to';
  static const analysisPending = 'جاري تحليل التسجيل…';
  static const analysisMono =
      'لم نجد قناة الشيخ منفصلة في هذا الملف (صُدِّر بدون يسار/يمين)، '
      'يمكن إضافة الملاحظات يدوياً';
  static const analysisFailed =
      'تعذّر تحليل التسجيل، يمكن إضافة الملاحظات يدوياً';

  // Two-file recordings (Task 11), for the teacher.
  static const analysisMerging = 'جارٍ دمج الملفين…';
  static const stemsLengthMismatchFailure =
      'تعذّر دمج الملفين: مدتهما غير متساوية. تأكد أنهما من نفس التسجيل، '
      'ثم احذف هذا التسجيل وارفعهما من جديد';
  static const stemsMisalignedFailure =
      'تعذّر دمج الملفين: صوت الشيخ لا يطابق صوت الطالب في التوقيت. '
      'صدّرهما من نفس الجلسة، ثم احذف هذا التسجيل وارفعهما من جديد';
  static const stemsFailure =
      'تعذّر دمج الملفين، احذف هذا التسجيل وارفعهما من جديد';
  static const swappedChip = 'تم تبديل الطالب والشيخ تلقائياً';
  static const nextMarker = 'التالي';
  static const previousMarker = 'السابق';
  static const addNoteHere = 'إضافة ملاحظة هنا';
  static const reviewedToggle = 'تمت المراجعة';
  static const newNoteTitle = 'ملاحظة جديدة';
  static const editNoteTitle = 'تعديل الملاحظة';
  static const addTextToVoice = 'إضافة نص';
  static const editNote = 'تعديل';
  static const deleteNote = 'حذف الملاحظة';
  static const deleteNoteConfirm = 'ستُحذف هذه الملاحظة نهائياً.';
  static const noteLabel = 'الملاحظة';
  static const noteRequired = 'اكتب الملاحظة';

  /// [max] arrives in Arabic-Indic digits.
  static String noteTooLong(String max) => 'الملاحظة $max حرفاً على الأكثر';
  static const ratingOptional = 'التقييم (اختياري)';
  static const clearRating = 'بلا تقييم';

  /// [stars] arrives in Arabic-Indic digits.
  static String rateStars(String stars) => 'تقييم $stars';
  static const noteSaved = 'تم حفظ الملاحظة';
  static const noteDeleted = 'تم حذف الملاحظة';
  static const markersLabel = 'مواضع ملاحظات الشيخ';

  /// [count] arrives in Arabic-Indic digits.
  static String markerCount(String count) => 'الملاحظات: $count';
  static const reviewedChip = 'تمت مراجعته';
  static const notReviewedChip = 'بانتظار المراجعة';

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
  static const errorStemsLengthMismatch =
      'مدة الملفين غير متساوية، تأكد أنهما من نفس التسجيل';
  static const errorRecordingFailed =
      'تعذّر التسجيل من الميكروفون على هذا الجهاز. حاول مرة أخرى.';
  static const errorUnknown = 'حدث خطأ غير متوقع. حاول مرة أخرى.';
}
