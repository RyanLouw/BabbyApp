import 'package:cloud_firestore/cloud_firestore.dart';

enum BabyEventType { feeding, sleep, nappy, note, medicine, temperature, bath, growth }
enum MilkType { formula, breastMilk, other }
enum NappyType { wet, dirty, both }

class BabyEvent {
  const BabyEvent({required this.id, required this.familyId, required this.babyId,
    required this.type, required this.start, required this.createdAt,
    required this.createdBy, required this.updatedAt, required this.updatedBy,
    this.end, this.notes, this.data = const {}});
  final String id, familyId, babyId, createdBy, updatedBy;
  final BabyEventType type;
  final DateTime start, createdAt, updatedAt;
  final DateTime? end;
  final String? notes;
  final Map<String, Object?> data;

  Duration duration([DateTime? now]) => (end ?? now ?? DateTime.now()).difference(start);
  Map<String, Object?> toFirestore() => {
    'familyId': familyId, 'babyId': babyId, 'eventType': type.name,
    'startDateTime': Timestamp.fromDate(start.toUtc()),
    'endDateTime': end == null ? null : Timestamp.fromDate(end!.toUtc()),
    'createdAt': Timestamp.fromDate(createdAt.toUtc()), 'createdBy': createdBy,
    'updatedAt': Timestamp.fromDate(updatedAt.toUtc()), 'updatedBy': updatedBy,
    'notes': notes, 'data': data,
  };
  factory BabyEvent.fromFirestore(String id, Map<String, Object?> json) {
    DateTime date(String key) => (json[key] as Timestamp).toDate().toUtc();
    return BabyEvent(id: id, familyId: json['familyId']! as String,
      babyId: json['babyId']! as String,
      type: BabyEventType.values.byName(json['eventType']! as String),
      start: date('startDateTime'), end: json['endDateTime'] == null ? null : date('endDateTime'),
      createdAt: date('createdAt'), createdBy: json['createdBy']! as String,
      updatedAt: date('updatedAt'), updatedBy: json['updatedBy']! as String,
      notes: json['notes'] as String?, data: Map<String, Object?>.from(json['data']! as Map));
  }
}
