import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/baby_event.dart';
import '../domain/event_repository.dart';

class FirestoreBabyEventRepository implements BabyEventRepository {
  FirestoreBabyEventRepository(this.db); final FirebaseFirestore db;
  CollectionReference<Map<String, dynamic>> _events(String family, String baby) =>
    db.collection('families').doc(family).collection('babies').doc(baby).collection('events');
  @override
  Stream<List<BabyEvent>> watchEvents({required String familyId, String? babyId}) {
    if (babyId == null) {
      return db.collectionGroup('events').where('familyId', isEqualTo: familyId)
        .orderBy('startDateTime', descending: true).snapshots(includeMetadataChanges: true)
        .map((s) => s.docs.map((d) => BabyEvent.fromFirestore(d.id, d.data())).toList());
    }
    return _events(familyId, babyId).orderBy('startDateTime', descending: true).snapshots(includeMetadataChanges: true)
      .map((s) => s.docs.map((d) => BabyEvent.fromFirestore(d.id, d.data())).toList());
  }
  @override Future<void> createEvent(BabyEvent e) => _events(e.familyId, e.babyId).doc(e.id).set(e.toFirestore());
  @override Future<void> updateEvent(BabyEvent e) => _events(e.familyId, e.babyId).doc(e.id).set(e.toFirestore(), SetOptions(merge: true));
  @override Future<void> deleteEvent({required String familyId, required String babyId, required String eventId}) => _events(familyId, babyId).doc(eventId).delete();
}
