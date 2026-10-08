// The seed data. Every id is fixed, so seeding again overwrites the same
// documents and accounts instead of adding new ones.
//
// Halaqat:  حلقة الفجر (t01, 5 students), حلقة العصر (t02, 5 students),
//           حلقة المغرب (t01, 2 students).
// s012 has no recordings (empty state). 25 recordings: 19 official,
// 6 practice (4 not reviewed); 4 with unread feedback; notes on 8
// recordings, rec-09 has 3.

export type Role = "admin" | "teacher" | "student";

export interface SeedUser {
  uid: string; // also the username
  fullName: string;
  role: Role;
  halaqaId?: string;
}

export interface SeedHalaqa {
  id: string;
  name: string;
  teacherId: string;
}

export interface SeedRecording {
  id: string;
  studentId: string;
  type: "official" | "practice";
  surahNumber: number;
  ayahFrom: number;
  ayahTo: number;
  recordedAt: string; // ISO date
  reviewed: boolean;
  unreadFeedback: boolean;
}

export interface SeedNote {
  id: string;
  recordingId: string;
  note: string;
  atSecond?: number;
  rating?: number;
}

export const emailDomain = "afdal-uloom.app";
export const devPassword = "test1234";

export const halaqat: SeedHalaqa[] = [
  { id: "halaqa-fajr", name: "حلقة الفجر", teacherId: "t01" },
  { id: "halaqa-asr", name: "حلقة العصر", teacherId: "t02" },
  { id: "halaqa-maghrib", name: "حلقة المغرب", teacherId: "t01" },
];

const studentNames = [
  "أحمد الخطيب",
  "عمر الحسن",
  "يوسف النجار",
  "إبراهيم السيد",
  "محمد العلي",
  "خالد منصور",
  "عبد الله سالم",
  "حمزة عيسى",
  "زيد قاسم",
  "بلال حداد",
  "مصطفى ناصر",
  "أنس جابر",
];

function halaqaOfStudent(index: number): string {
  if (index < 5) return "halaqa-fajr";
  if (index < 10) return "halaqa-asr";
  return "halaqa-maghrib";
}

export const users: SeedUser[] = [
  { uid: "shadi", fullName: "شادي", role: "admin" },
  { uid: "t01", fullName: "الشيخ محمود", role: "teacher" },
  { uid: "t02", fullName: "الشيخ عبد الرحمن", role: "teacher" },
  ...studentNames.map(
    (fullName, i): SeedUser => ({
      uid: `s${String(i + 1).padStart(3, "0")}`,
      fullName,
      role: "student",
      halaqaId: halaqaOfStudent(i),
    }),
  ),
];

type Row = [
  id: string,
  studentId: string,
  type: "official" | "practice",
  surah: number,
  from: number,
  to: number,
  date: string,
  reviewed: boolean,
  unread: boolean,
];

// Official studio recordings are reviewed by definition.
const rows: Row[] = [
  ["rec-01", "s001", "official", 1, 1, 7, "2026-09-01", true, false],
  ["rec-02", "s001", "official", 2, 1, 20, "2026-09-08", true, true],
  ["rec-03", "s001", "official", 2, 21, 40, "2026-09-15", true, false],
  ["rec-04", "s002", "official", 67, 1, 15, "2026-09-02", true, true],
  ["rec-05", "s002", "official", 67, 16, 30, "2026-09-09", true, false],
  ["rec-06", "s003", "official", 78, 1, 20, "2026-09-03", true, false],
  ["rec-07", "s003", "official", 78, 21, 40, "2026-09-10", true, false],
  ["rec-08", "s004", "official", 36, 1, 27, "2026-09-04", true, false],
  ["rec-09", "s005", "official", 55, 1, 25, "2026-09-05", true, true],
  ["rec-10", "s006", "official", 18, 1, 10, "2026-09-02", true, false],
  ["rec-11", "s006", "official", 18, 11, 26, "2026-09-09", true, false],
  ["rec-12", "s007", "official", 112, 1, 4, "2026-09-03", true, false],
  ["rec-13", "s007", "official", 114, 1, 6, "2026-09-10", true, false],
  ["rec-14", "s008", "official", 3, 1, 20, "2026-09-04", true, true],
  ["rec-15", "s009", "official", 2, 255, 257, "2026-09-05", true, false],
  ["rec-16", "s010", "official", 36, 28, 54, "2026-09-06", true, false],
  ["rec-17", "s011", "official", 67, 1, 30, "2026-09-07", true, false],
  ["rec-18", "s011", "official", 1, 1, 7, "2026-09-14", true, false],
  ["rec-19", "s004", "official", 36, 28, 50, "2026-09-11", true, false],
  ["rec-20", "s001", "practice", 2, 41, 50, "2026-09-20", false, false],
  ["rec-21", "s002", "practice", 67, 1, 10, "2026-09-21", true, false],
  ["rec-22", "s006", "practice", 18, 27, 31, "2026-09-22", false, false],
  ["rec-23", "s008", "practice", 3, 21, 30, "2026-09-23", false, false],
  ["rec-24", "s011", "practice", 112, 1, 4, "2026-09-24", false, false],
  ["rec-25", "s010", "practice", 55, 26, 40, "2026-09-25", true, false],
];

export const recordings: SeedRecording[] = rows.map(
  ([id, studentId, type, surahNumber, ayahFrom, ayahTo, date, reviewed, unreadFeedback]) => ({
    id,
    studentId,
    type,
    surahNumber,
    ayahFrom,
    ayahTo,
    recordedAt: `${date}T16:00:00Z`,
    reviewed,
    unreadFeedback,
  }),
);

export const notes: SeedNote[] = [
  { id: "fb-01", recordingId: "rec-02", note: "أحسنت، انتبه لمدّ الألف في آية ٥", atSecond: 48, rating: 4 },
  { id: "fb-02", recordingId: "rec-04", note: "راجع مخارج الحروف في الآيات الأولى", rating: 3 },
  { id: "fb-03", recordingId: "rec-07", note: "تلاوة جميلة، بارك الله فيك", rating: 5 },
  { id: "fb-04", recordingId: "rec-09", note: "انتبه للغنّة في النون المشدّدة", atSecond: 15 },
  { id: "fb-05", recordingId: "rec-09", note: "الوقف هنا غير مناسب، أعد الآية", atSecond: 92 },
  { id: "fb-06", recordingId: "rec-09", note: "تحسّن واضح في آخر التلاوة", rating: 4 },
  { id: "fb-07", recordingId: "rec-11", note: "ممتاز، استمر على هذا", rating: 5 },
  { id: "fb-08", recordingId: "rec-14", note: "أعد قراءة الآية ١٢ ببطء", atSecond: 130, rating: 3 },
  { id: "fb-09", recordingId: "rec-16", note: "حفظ متقن", rating: 5 },
  { id: "fb-10", recordingId: "rec-21", note: "تدريب جيد، ركّز على أحكام الإدغام", atSecond: 20 },
];
