// Helpers shared by the Firestore repositories: Timestamp <-> DateTime
// conversion and wrapping every Firebase call so it throws AppException.
import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/firestore_paths.dart';
import '../errors/firebase_error_mapper.dart';

/// Reads with pending server timestamps estimated from the local clock, so
/// a document written a moment ago never has a null `createdAt`.
const estimateServerTimestamps = GetOptions(
  serverTimestampBehavior: ServerTimestampBehavior.estimate,
);

/// The model map of [doc]: every [Timestamp] becomes a [DateTime].
///
/// `snapshots()` has no ServerTimestampBehavior option, so a local write
/// whose `createdAt` the server has not set yet arrives as null; it gets the
/// local time, which is what [ServerTimestampBehavior.estimate] does.
Map<String, dynamic> readDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
  final data = {
    for (final MapEntry(:key, :value) in doc.data()!.entries)
      key: value is Timestamp ? value.toDate() : value,
  };
  if (data[Fields.createdAt] == null && doc.metadata.hasPendingWrites) {
    data[Fields.createdAt] = DateTime.now();
  }
  return data;
}

/// The Firestore map of a model map: every [DateTime] becomes a [Timestamp].
Map<String, dynamic> toFirestore(Map<String, dynamic> map) => {
  for (final MapEntry(:key, :value) in map.entries)
    key: value is DateTime ? Timestamp.fromDate(value) : value,
};

/// The document at [ref], parsed by [parse], then every change; null once
/// it does not exist.
///
/// "Does not exist" is only reported when the server says so: offline, the
/// local cache answers "missing" for any document it never saw, which
/// would sign a user out (their profile) or close a page as deleted. Such
/// a snapshot is skipped and the stream waits for the server.
Stream<T?> watchDocument<T>(
  DocumentReference<Map<String, dynamic>> ref,
  T Function(String id, Map<String, dynamic> map) parse,
) => guardStream(
  ref
      .snapshots()
      .where((doc) => doc.exists || !doc.metadata.isFromCache)
      .map((doc) => doc.exists ? parse(doc.id, readDocument(doc)) : null),
);

/// Runs [action] and rethrows any error as an AppException.
Future<T> guard<T>(Future<T> Function() action) async {
  try {
    return await action();
  } catch (error, stackTrace) {
    throw toAppException(error, stackTrace);
  }
}

/// [stream] with every error event (Firebase or model parsing) turned into
/// an AppException.
Stream<T> guardStream<T>(Stream<T> stream) => stream.handleError(
  (Object error, StackTrace stackTrace) =>
      throw toAppException(error, stackTrace),
);
