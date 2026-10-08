import 'package:afdal_uloom_tilawat/core/data/firestore_feedback_repository.dart';
import 'package:afdal_uloom_tilawat/core/data/firestore_halaqa_repository.dart';
import 'package:afdal_uloom_tilawat/core/data/firestore_recording_repository.dart';
import 'package:afdal_uloom_tilawat/core/data/firestore_user_repository.dart';
import 'package:afdal_uloom_tilawat/core/providers/repository_providers.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'repositories are the Firestore ones, on the injected instance',
    () async {
      final db = FakeFirebaseFirestore();
      final container = ProviderContainer(
        overrides: [firestoreProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      expect(
        container.read(userRepositoryProvider),
        isA<FirestoreUserRepository>(),
      );
      expect(
        container.read(halaqaRepositoryProvider),
        isA<FirestoreHalaqaRepository>(),
      );
      expect(
        container.read(recordingRepositoryProvider),
        isA<FirestoreRecordingRepository>(),
      );
      expect(
        container.read(feedbackRepositoryProvider),
        isA<FirestoreFeedbackRepository>(),
      );

      // Writes through a repository land in the injected instance.
      final id = await container
          .read(halaqaRepositoryProvider)
          .create(name: 'حلقة', teacherId: 't1');
      expect((await db.doc('halaqat/$id').get()).exists, isTrue);
    },
  );
}
