import 'package:flutter_test/flutter_test.dart';
import 'package:babby_care/features/events/domain/baby_event.dart';
import 'package:babby_care/features/family/domain/family.dart';
import 'package:babby_care/features/statistics/domain/care_statistics.dart';
BabyEvent event(BabyEventType type, DateTime start, {DateTime? end, Map<String,Object?> data=const {}}) => BabyEvent(id:'1',familyId:'f',babyId:'b',type:type,start:start,end:end,createdAt:start,createdBy:'u',updatedAt:start,updatedBy:'u',data:data);
void main(){
  test('feeding totals and average use bottle amounts',(){final now=DateTime.utc(2026,1,2);final stats=CareStatistics([event(BabyEventType.feeding,now,data:{'amountMl':90}),event(BabyEventType.feeding,now,data:{'amountMl':110})],now.subtract(const Duration(days:1)));expect(stats.feedCount,2);expect(stats.totalMl,200);expect(stats.averageBottleMl,100);});
  test('sleep duration is derived from persisted timestamps',(){final start=DateTime.utc(2026);expect(event(BabyEventType.sleep,start,end:start.add(const Duration(minutes:75))).duration(),const Duration(minutes:75));});
  test('date filtering excludes old events',(){final now=DateTime.utc(2026,2,2);expect(CareStatistics([event(BabyEventType.note,now.subtract(const Duration(days:2))),event(BabyEventType.note,now)],now.subtract(const Duration(days:1))).events.length,1);});
  test('only owners manage a family',(){expect(const FamilyPermissions(FamilyRole.owner).canManageFamily,isTrue);expect(const FamilyPermissions(FamilyRole.caregiver).canManageFamily,isFalse);expect(const FamilyPermissions(FamilyRole.caregiver).canRecordEvents,isTrue);});
}
