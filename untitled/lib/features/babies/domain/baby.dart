import 'package:cloud_firestore/cloud_firestore.dart';

class Baby {
  const Baby({required this.id, required this.familyId, required this.name,
    required this.dateOfBirth, required this.createdAt, required this.createdBy, this.profileImage});
  final String id, familyId, name, createdBy;
  final DateTime dateOfBirth, createdAt;
  final String? profileImage;
  Map<String, Object?> toFirestore() => {
    'familyId': familyId,
    'name': name,
    'dateOfBirth': Timestamp.fromDate(dateOfBirth.toUtc()),
    'profileImage': profileImage,
    'createdAt': Timestamp.fromDate(createdAt.toUtc()),
    'createdBy': createdBy,
  };
  factory Baby.fromFirestore(String id, Map<String, Object?> value) => Baby(id: id,
    familyId: value['familyId']! as String, name: value['name']! as String,
    dateOfBirth: (value['dateOfBirth']! as Timestamp).toDate(),
    createdAt: (value['createdAt']! as Timestamp).toDate(),
    createdBy: value['createdBy']! as String, profileImage: value['profileImage'] as String?);
}
