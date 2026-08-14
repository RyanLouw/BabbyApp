import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/data/auth_repository.dart';
import '../features/babies/domain/baby.dart';
import '../features/events/data/firestore_event_repository.dart';
import '../features/events/domain/event_repository.dart';
import '../features/events/domain/baby_event.dart';
import '../features/family/data/family_repository.dart';

final authRepositoryProvider = Provider(
  (ref) => AuthRepository(FirebaseAuth.instance),
);
final authStateProvider = StreamProvider(
  (ref) => ref.watch(authRepositoryProvider).watch(),
);
final eventRepositoryProvider = Provider<BabyEventRepository>(
  (ref) => FirestoreBabyEventRepository(FirebaseFirestore.instance),
);
final familyRepositoryProvider = Provider(
  (ref) => FamilyRepository(FirebaseFirestore.instance, FirebaseAuth.instance),
);
final currentFamilyIdProvider = StreamProvider<String?>(
  (ref) => ref.watch(familyRepositoryProvider).watchCurrentFamilyId(),
);
final babiesProvider = StreamProvider.family<List<Baby>, String>(
  (ref, familyId) => ref.watch(familyRepositoryProvider).watchBabies(familyId),
);
final babyEventsProvider = StreamProvider.family<
    List<BabyEvent>,
    ({String familyId, String babyId})>(
  (ref, key) => ref.watch(eventRepositoryProvider).watchEvents(
        familyId: key.familyId,
        babyId: key.babyId,
      ),
);
final familyEventsProvider = StreamProvider.family<List<BabyEvent>, String>(
  (ref, familyId) => ref.watch(eventRepositoryProvider).watchEvents(
        familyId: familyId,
      ),
);
