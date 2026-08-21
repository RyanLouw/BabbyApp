import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/feeding_goal.dart';

class FeedingGoalRepository {
  FeedingGoalRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _goals(
    String familyId,
    String babyId,
  ) =>
      _firestore
          .collection('families')
          .doc(familyId)
          .collection('babies')
          .doc(babyId)
          .collection('feedingGoals');

  Stream<List<FeedingGoal>> watchGoals({
    required String familyId,
    required String babyId,
  }) =>
      _goals(familyId, babyId)
          .orderBy('effectiveFrom')
          .snapshots(includeMetadataChanges: true)
          .map(
            (snapshot) => snapshot.docs
                .map(
                  (document) => FeedingGoal.fromFirestore(
                    document.id,
                    document.data(),
                  ),
                )
                .toList(),
          );

  Future<void> createGoal(FeedingGoal goal) =>
      _goals(goal.familyId, goal.babyId)
          .doc(goal.id)
          .set(goal.toFirestore());
}
