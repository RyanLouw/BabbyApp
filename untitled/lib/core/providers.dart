import 'dart:async';

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
  (ref, familyId) async* {
    final babies = await ref.watch(babiesProvider(familyId).future);
    if (babies.isEmpty) {
      yield const [];
      return;
    }

    final repository = ref.watch(eventRepositoryProvider);
    final eventsByBaby = <String, List<BabyEvent>>{};
    final controller = StreamController<List<BabyEvent>>();
    final subscriptions = <StreamSubscription<List<BabyEvent>>>[];

    void publish() {
      final events = eventsByBaby.values.expand((items) => items).toList()
        ..sort((a, b) => b.start.compareTo(a.start));
      controller.add(events);
    }

    for (final baby in babies) {
      subscriptions.add(
        repository
            .watchEvents(familyId: familyId, babyId: baby.id)
            .listen((events) {
          eventsByBaby[baby.id] = events;
          publish();
        }, onError: controller.addError),
      );
    }
    ref.onDispose(() {
      unawaited(
        Future.wait(subscriptions.map((subscription) => subscription.cancel()))
            .whenComplete(controller.close),
      );
    });
    yield* controller.stream;
  },
);
