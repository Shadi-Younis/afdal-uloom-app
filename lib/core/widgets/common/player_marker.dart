/// A place shown on the player's seek bar: a note's moment and, for the
/// sheikh's voice markers, where he stopped speaking.
class PlayerMarker {
  const PlayerMarker({required this.start, this.end});

  final Duration start;

  /// Null for a note about a single moment.
  final Duration? end;

  @override
  bool operator ==(Object other) =>
      other is PlayerMarker && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'PlayerMarker($start..$end)';
}
