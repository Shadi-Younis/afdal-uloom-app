/// Firestore collection and subcollection names, from the data model in
/// docs/PROJECT_PLAN.md section 3. Field names are in [Fields].
abstract final class FirestorePaths {
  static const users = 'users';
  static const halaqat = 'halaqat';
  static const recordings = 'recordings';

  /// Subcollection of `users/{uid}`, one document per surah number.
  static const progress = 'progress';

  /// Subcollection of `recordings/{recordingId}`.
  static const feedback = 'feedback';

  static String user(String uid) => '$users/$uid';
  static String userProgress(String uid) => '$users/$uid/$progress';
  static String halaqa(String halaqaId) => '$halaqat/$halaqaId';
  static String recording(String recordingId) => '$recordings/$recordingId';
  static String recordingFeedback(String recordingId) =>
      '$recordings/$recordingId/$feedback';
}

/// Firestore field names, from docs/PROJECT_PLAN.md section 3.
abstract final class Fields {
  // Shared
  static const createdAt = 'createdAt';
  static const updatedAt = 'updatedAt';
  static const halaqaId = 'halaqaId';
  static const teacherId = 'teacherId';

  // users
  static const username = 'username';
  static const fullName = 'fullName';
  static const role = 'role';
  static const studentCode = 'studentCode';
  static const fcmTokens = 'fcmTokens';
  static const disabled = 'disabled';

  // users/{uid}/progress
  static const status = 'status';
  static const updatedBy = 'updatedBy';

  // halaqat
  static const name = 'name';

  // recordings
  static const studentId = 'studentId';
  static const uploadedBy = 'uploadedBy';
  static const type = 'type';
  static const surahNumber = 'surahNumber';
  static const ayahFrom = 'ayahFrom';
  static const ayahTo = 'ayahTo';
  static const storagePath = 'storagePath';
  static const durationSec = 'durationSec';
  static const recordedAt = 'recordedAt';
  static const unreadFeedback = 'unreadFeedback';
  static const reviewed = 'reviewed';

  // recordings/{recordingId}/feedback
  static const note = 'note';
  static const atSecond = 'atSecond';
  static const rating = 'rating';
}
