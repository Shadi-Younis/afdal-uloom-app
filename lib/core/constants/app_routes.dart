/// Route paths and names for go_router.
abstract final class AppRoutes {
  /// Shown while the session is still unknown at start-up.
  static const splash = '/';
  static const login = '/login';
  static const admin = '/admin';
  static const teacher = '/teacher';
  static const student = '/student';

  /// One recording, for every role: `/recording/{recordingId}`. Who may
  /// open which one is decided by the security rules, not the router.
  static const recordingBase = '/recording';
  static const recordingPath = '$recordingBase/:$idParam';
  static String recording(String recordingId) => '$recordingBase/$recordingId';

  /// The signed-in user's own account ("حسابي"), for every role.
  static const account = '/account';

  /// The student's practice recorder («سجّل تدريباً»).
  static const practiceSegment = 'practice';
  static const studentPractice = '$student/$practiceSegment';

  /// The teacher's review queue («بانتظار المراجعة»).
  static const reviewSegment = 'review';
  static const teacherReview = '$teacher/$reviewSegment';

  // Teacher pages, under /teacher (the role guard protects them).
  static const teacherHalaqatSegment = 'halaqat';
  static const uploadSegment = 'upload';
  static String teacherHalaqa(String halaqaId) =>
      '$teacher/$teacherHalaqatSegment/$halaqaId';
  static String teacherStudent(String halaqaId, String studentId) =>
      '${teacherHalaqa(halaqaId)}/$studentsSegment/$studentId';
  static const teacherHalaqaPath = '$teacherHalaqatSegment/:$idParam';

  /// The upload page (studio recordings) of a teacher and of an admin;
  /// [studentId] fills in the student of the first row.
  static String teacherUpload({String? studentId}) =>
      _withStudent('$teacher/$uploadSegment', studentId);
  static String adminUpload({String? studentId}) =>
      _withStudent('$admin/$uploadSegment', studentId);
  static const adminUploadPath = '$admin/$uploadSegment';

  /// Query parameter of the upload pages.
  static const studentQuery = 'student';

  static String _withStudent(String path, String? studentId) =>
      studentId == null
      ? path
      : Uri(path: path, queryParameters: {studentQuery: studentId}).toString();

  static const splashName = 'splash';
  static const accountName = 'account';
  static const recordingName = 'recording';
  static const loginName = 'login';
  static const adminName = 'admin';
  static const teacherName = 'teacher';
  static const studentName = 'student';

  // Admin panel: one branch per section of the navigation bar. Every path
  // stays under /admin, which the role guard protects.
  static const adminHalaqat = '/admin/halaqat';
  static const adminTeachers = '/admin/teachers';
  static const adminStudents = '/admin/students';
  static const adminNewHalaqa = '$adminHalaqat/$newSegment';
  static const adminNewTeacher = '$adminTeachers/$newSegment';
  static const adminNewStudent = '$adminStudents/$newSegment';

  /// Admins are listed in the teachers section.
  static const adminNewAdmin = '$adminTeachers/$newAdminSegment';
  static String adminAdmin(String adminId) =>
      '$adminTeachers/$adminSegment/$adminId';

  static String adminHalaqa(String halaqaId) => '$adminHalaqat/$halaqaId';
  static String adminTeacher(String teacherId) => '$adminTeachers/$teacherId';
  static String adminStudent(String studentId) => '$adminStudents/$studentId';

  /// The students list showing only halaqa [halaqaId] (its filter chip
  /// selected).
  static String adminStudentsOfHalaqa(String halaqaId) => Uri(
    path: adminStudents,
    queryParameters: {halaqaQuery: halaqaId},
  ).toString();

  /// The add-student form with [halaqaId] chosen, inside the halaqat
  /// section (back returns to the halaqa).
  static String adminHalaqaAddStudent(String halaqaId) =>
      '${adminHalaqa(halaqaId)}/$addStudentSegment';

  /// A student's details opened from their halaqa.
  static String adminHalaqaStudent(String halaqaId, String studentId) =>
      '${adminHalaqa(halaqaId)}/$studentsSegment/$studentId';

  // Relative paths of the nested admin routes (app/router.dart). `new` is
  // matched before `:id`; Firestore ids are never "new".
  static const newSegment = 'new';
  static const newAdminSegment = 'new-admin';
  static const adminSegment = 'admin';
  static const adminAdminPath = '$adminSegment/:$idParam';
  static const addStudentSegment = 'add-student';
  static const studentsSegment = 'students';
  static const idParam = 'id';

  /// Query parameter of [adminStudentsOfHalaqa].
  static const halaqaQuery = 'halaqa';
  static const studentIdParam = 'studentId';
  static const idPath = ':$idParam';
  static const halaqaStudentPath = '$studentsSegment/:$studentIdParam';

  /// Where "back" leads from [location] when there is no page under it to
  /// return to (opened from a link or a web refresh): its logical parent.
  /// Null for root pages: login, the role homes and the admin's sections.
  /// One explicit entry per drill-down route.
  static String? parentOf(String location) {
    final path = Uri.parse(location).path;
    for (final (pattern, parent) in _parents) {
      final match = pattern.firstMatch(path);
      if (match != null) return parent(match);
    }
    return null;
  }

  static final _parents = <(RegExp, String Function(RegExpMatch))>[
    // /admin/halaqat/new, /admin/halaqat/:id
    (RegExp(r'^/admin/halaqat/[^/]+$'), (_) => adminHalaqat),
    // /admin/halaqat/:id/add-student, /admin/halaqat/:id/students/:studentId
    (
      RegExp(
        '^/admin/halaqat/([^/]+)/($addStudentSegment|$studentsSegment/[^/]+)\$',
      ),
      (m) => adminHalaqa(m[1]!),
    ),
    // /admin/teachers/new, /admin/teachers/new-admin, /admin/teachers/:id
    (RegExp(r'^/admin/teachers/[^/]+$'), (_) => adminTeachers),
    // /admin/teachers/admin/:id
    (RegExp('^/admin/teachers/$adminSegment/[^/]+\$'), (_) => adminTeachers),
    // /admin/students/new, /admin/students/:id
    (RegExp(r'^/admin/students/[^/]+$'), (_) => adminStudents),
    // /teacher/halaqat/:id, /teacher/upload, /teacher/review
    (
      RegExp(
        '^/teacher/($teacherHalaqatSegment/[^/]+|$uploadSegment|$reviewSegment)\$',
      ),
      (_) => teacher,
    ),
    // /student/practice
    (RegExp('^/student/$practiceSegment\$'), (_) => student),
    // /teacher/halaqat/:id/students/:studentId
    (
      RegExp(
        '^/teacher/$teacherHalaqatSegment/([^/]+)/$studentsSegment/[^/]+\$',
      ),
      (m) => teacherHalaqa(m[1]!),
    ),
    // /admin/upload
    (RegExp('^/admin/$uploadSegment\$'), (_) => admin),
    // /recording/:id and /account: the role's home (the splash route
    // redirects there).
    (RegExp(r'^/recording/[^/]+$'), (_) => splash),
    (RegExp(r'^/account$'), (_) => splash),
  ];

  static const adminHalaqatName = 'adminHalaqat';
  static const adminNewHalaqaName = 'adminNewHalaqa';
  static const adminHalaqaName = 'adminHalaqa';
  static const adminHalaqaAddStudentName = 'adminHalaqaAddStudent';
  static const adminHalaqaStudentName = 'adminHalaqaStudent';
  static const adminTeachersName = 'adminTeachers';
  static const adminNewTeacherName = 'adminNewTeacher';
  static const adminTeacherName = 'adminTeacher';
  static const adminNewAdminName = 'adminNewAdmin';
  static const adminAdminName = 'adminAdmin';
  static const adminStudentsName = 'adminStudents';
  static const adminNewStudentName = 'adminNewStudent';
  static const adminStudentName = 'adminStudent';
  static const adminUploadName = 'adminUpload';
  static const teacherHalaqaName = 'teacherHalaqa';
  static const teacherStudentName = 'teacherStudent';
  static const teacherUploadName = 'teacherUpload';
  static const teacherReviewName = 'teacherReview';
  static const studentPracticeName = 'studentPractice';
}
