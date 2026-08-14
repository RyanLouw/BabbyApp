import 'baby_event.dart';
abstract interface class BabyEventRepository {
  Stream<List<BabyEvent>> watchEvents({required String familyId, String? babyId});
  Future<void> createEvent(BabyEvent event);
  Future<void> updateEvent(BabyEvent event);
  Future<void> deleteEvent({required String familyId, required String babyId, required String eventId});
}
