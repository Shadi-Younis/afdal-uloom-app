/// Route paths and names for go_router.
abstract final class AppRoutes {
  /// Shown while the session is still unknown at start-up.
  static const splash = '/';
  static const login = '/login';
  static const admin = '/admin';
  static const teacher = '/teacher';
  static const student = '/student';

  static const splashName = 'splash';
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

  static String adminHalaqa(String halaqaId) => '$adminHalaqat/$halaqaId';
  static String adminTeacher(String teacherId) => '$adminTeachers/$teacherId';
  static String adminStudent(String studentId) => '$adminStudents/$studentId';

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
  static const addStudentSegment = 'add-student';
  static const studentsSegment = 'students';
  static const idParam = 'id';
  static const studentIdParam = 'studentId';
  static const idPath = ':$idParam';
  static const halaqaStudentPath = '$studentsSegment/:$studentIdParam';

  static const adminHalaqatName = 'adminHalaqat';
  static const adminNewHalaqaName = 'adminNewHalaqa';
  static const adminHalaqaName = 'adminHalaqa';
  static const adminHalaqaAddStudentName = 'adminHalaqaAddStudent';
  static const adminHalaqaStudentName = 'adminHalaqaStudent';
  static const adminTeachersName = 'adminTeachers';
  static const adminNewTeacherName = 'adminNewTeacher';
  static const adminTeacherName = 'adminTeacher';
  static const adminStudentsName = 'adminStudents';
  static const adminNewStudentName = 'adminNewStudent';
  static const adminStudentName = 'adminStudent';
}
