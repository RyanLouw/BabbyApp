import 'package:cloud_firestore/cloud_firestore.dart';

class FeedingGoal {
  const FeedingGoal({
    required this.id,
    required this.familyId,
    required this.babyId,
    required this.dailyMl,
    required this.effectiveFrom,
    required this.createdAt,
    required this.createdBy,
  });

  final String id;
  final String familyId;
  final String babyId;
  final int dailyMl;
  final DateTime effectiveFrom;
  final DateTime createdAt;
  final String createdBy;

  Map<String, Object?> toFirestore() => {
        'familyId': familyId,
        'babyId': babyId,
        'dailyMl': dailyMl,
        'effectiveFrom': Timestamp.fromDate(effectiveFrom.toUtc()),
        'createdAt': Timestamp.fromDate(createdAt.toUtc()),
        'createdBy': createdBy,
      };

  factory FeedingGoal.fromFirestore(
    String id,
    Map<String, Object?> value,
  ) =>
      FeedingGoal(
        id: id,
        familyId: value['familyId']! as String,
        babyId: value['babyId']! as String,
        dailyMl: (value['dailyMl']! as num).round(),
        effectiveFrom: (value['effectiveFrom']! as Timestamp).toDate(),
        createdAt: (value['createdAt']! as Timestamp).toDate(),
        createdBy: value['createdBy']! as String,
      );
}

FeedingGoal? feedingGoalOn(List<FeedingGoal> goals, DateTime date) {
  FeedingGoal? result;
  for (final goal in goals) {
    if (!goal.effectiveFrom.isAfter(date) &&
        (result == null || goal.effectiveFrom.isAfter(result.effectiveFrom))) {
      result = goal;
    }
  }
  return result;
}
