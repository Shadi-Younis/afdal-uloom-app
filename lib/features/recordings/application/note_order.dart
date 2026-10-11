/// The notes of a recording in the order of the recitation, and the
/// markers the player shows for them.
library;

import '../../../core/constants/app_durations.dart';
import '../../../core/models/feedback_note.dart';
import '../../../core/widgets/common/player_marker.dart';

/// Notes about a moment first, by that moment (then by creation); notes
/// about the whole recording after them, oldest first.
List<FeedbackNote> notesInTimeOrder(List<FeedbackNote> notes) {
  int compare(FeedbackNote a, FeedbackNote b) {
    final at = a.atSecond, bt = b.atSecond;
    if (at != null && bt != null && at != bt) return at.compareTo(bt);
    if (at != null && bt == null) return -1;
    if (at == null && bt != null) return 1;
    return a.createdAt.compareTo(b.createdAt);
  }

  return [...notes]..sort(compare);
}

/// One marker per note about a moment, in time order.
List<PlayerMarker> markersOf(List<FeedbackNote> notes) => [
  for (final note in notesInTimeOrder(notes))
    if (note.atSecond case final at?)
      PlayerMarker(
        start: Duration(seconds: at),
        end: switch (note.endSecond) {
          final end? => Duration(seconds: end),
          null => null,
        },
      ),
];

/// Where «التالي» goes from [position]: the first marker after it (one the
/// player is almost at does not count), or null after the last one.
Duration? nextMarkerAfter(Duration position, List<PlayerMarker> markers) {
  for (final marker in markers) {
    if (marker.start > position + AppDurations.nextMarkerTolerance) {
      return marker.start;
    }
  }
  return null;
}

/// Where «السابق» goes from [position]: the last marker before it (just
/// past a marker's start, the one before that), or null before the first.
Duration? previousMarkerBefore(
  Duration position,
  List<PlayerMarker> markers,
) {
  for (final marker in markers.reversed) {
    if (marker.start < position - AppDurations.previousMarkerTolerance) {
      return marker.start;
    }
  }
  return null;
}
