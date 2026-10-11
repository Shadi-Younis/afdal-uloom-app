import 'package:afdal_uloom_tilawat/core/models/feedback_kind.dart';
import 'package:afdal_uloom_tilawat/core/models/feedback_note.dart';
import 'package:afdal_uloom_tilawat/core/widgets/common/player_marker.dart';
import 'package:afdal_uloom_tilawat/features/recordings/application/note_order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FeedbackNote note(String id, {int? at, int? end, int day = 1}) =>
      FeedbackNote(
        id: id,
        teacherId: 't1',
        note: end == null ? 'نص' : '',
        kind: end == null ? FeedbackKind.text : FeedbackKind.voice,
        atSecond: at,
        endSecond: end,
        createdAt: DateTime(2026, 10, day),
      );

  test('moments first by time (then age), whole-recording notes last', () {
    final sorted = notesInTimeOrder([
      note('general-new', day: 5),
      note('at-30', at: 30),
      note('general-old', day: 2),
      note('at-5-newer', at: 5, day: 3),
      note('voice-5', at: 5, end: 9, day: 1),
    ]);
    expect(sorted.map((n) => n.id), [
      'voice-5',
      'at-5-newer',
      'at-30',
      'general-old',
      'general-new',
    ]);
  });

  test('markers: one per moment, voice spans with their end', () {
    expect(markersOf([note('g'), note('v', at: 5, end: 9), note('t', at: 2)]), [
      const PlayerMarker(start: Duration(seconds: 2)),
      const PlayerMarker(
        start: Duration(seconds: 5),
        end: Duration(seconds: 9),
      ),
    ]);
  });

  group('next and previous', () {
    const markers = [
      PlayerMarker(start: Duration(seconds: 5)),
      PlayerMarker(start: Duration(seconds: 12)),
      PlayerMarker(start: Duration(seconds: 20)),
    ];
    Duration s(num seconds) => Duration(milliseconds: (seconds * 1000).round());

    test('next: the first marker clearly after the position', () {
      expect(nextMarkerAfter(Duration.zero, markers), s(5));
      // Just jumped to 5: next goes on to 12.
      expect(nextMarkerAfter(s(5), markers), s(12));
      expect(nextMarkerAfter(s(4.6), markers), s(12));
      expect(nextMarkerAfter(s(4.4), markers), s(5));
      expect(nextMarkerAfter(s(20), markers), isNull);
      expect(nextMarkerAfter(Duration.zero, const []), isNull);
    });

    test('previous: the last marker clearly before the position', () {
      expect(previousMarkerBefore(s(13), markers), s(5));
      expect(previousMarkerBefore(s(14), markers), s(12));
      expect(previousMarkerBefore(s(30), markers), s(20));
      expect(previousMarkerBefore(s(6), markers), isNull);
      expect(previousMarkerBefore(Duration.zero, markers), isNull);
    });
  });
}
