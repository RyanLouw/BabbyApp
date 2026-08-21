import 'package:flutter_test/flutter_test.dart';
import 'package:babby_care/features/events/domain/baby_event.dart';
import 'package:babby_care/features/family/domain/family.dart';
import 'package:babby_care/features/statistics/domain/care_statistics.dart';
import 'package:babby_care/features/statistics/presentation/statistics_screen.dart';
import 'package:babby_care/features/auth/domain/auth_redirect.dart';
import 'package:babby_care/features/reminders/domain/care_reminder.dart';
import 'package:babby_care/features/goals/domain/feeding_goal.dart';
BabyEvent event(BabyEventType type, DateTime start, {DateTime? end, Map<String,Object?> data=const {}}) => BabyEvent(id:'1',familyId:'f',babyId:'b',type:type,start:start,end:end,createdAt:start,createdBy:'u',updatedAt:start,updatedBy:'u',data:data);
void main(){
  test('feeding targets retain history and select the target for a date', () {
    FeedingGoal goal(int ml, DateTime from) => FeedingGoal(
      id: '$ml', familyId: 'f', babyId: 'b', dailyMl: ml,
      effectiveFrom: from, createdAt: from, createdBy: 'u');
    final goals = [
      goal(600, DateTime.utc(2026, 1, 1)),
      goal(750, DateTime.utc(2026, 2, 1)),
    ];
    expect(feedingGoalOn(goals, DateTime.utc(2026, 1, 20))?.dailyMl, 600);
    expect(feedingGoalOn(goals, DateTime.utc(2026, 2, 20))?.dailyMl, 750);
    expect(feedingGoalOn(goals, DateTime.utc(2025, 12, 20)), isNull);
  });
  test('care reminders round-trip through local storage JSON', () {
    const reminder = CareReminder(id: 42, type: CareReminderType.feeding, hour: 6, minute: 30, enabled: false);
    final decoded = CareReminder.fromJson(reminder.toJson());
    expect(decoded.id, 42);
    expect(decoded.type, CareReminderType.feeding);
    expect(decoded.hour, 6);
    expect(decoded.minute, 30);
    expect(decoded.enabled, isFalse);
  });
  test('feeding totals and average use bottle amounts',(){final now=DateTime.utc(2026,1,2);final stats=CareStatistics([event(BabyEventType.feeding,now,data:{'amountMl':90}),event(BabyEventType.feeding,now,data:{'amountMl':110})],now.subtract(const Duration(days:1)));expect(stats.feedCount,2);expect(stats.totalMl,200);expect(stats.averageBottleMl,100);});
  test('breastfeeds do not reduce the average bottle amount',(){final now=DateTime.utc(2026,1,2);final stats=CareStatistics([event(BabyEventType.feeding,now,data:{'amountMl':90}),event(BabyEventType.feeding,now,data:{'kind':'breast'})],now.subtract(const Duration(days:1)));expect(stats.feedCount,2);expect(stats.averageBottleMl,90);});
  test('sleep duration is derived from persisted timestamps',(){final start=DateTime.utc(2026);expect(event(BabyEventType.sleep,start,end:start.add(const Duration(minutes:75))).duration(),const Duration(minutes:75));});
  test('date filtering excludes old events',(){final now=DateTime.utc(2026,2,2);expect(CareStatistics([event(BabyEventType.note,now.subtract(const Duration(days:2))),event(BabyEventType.note,now)],now.subtract(const Duration(days:1))).events.length,1);});
  test('today statistics start at local midnight, not 24 hours ago', () {
    final now = DateTime(2026, 8, 19, 15, 30);
    expect(statisticsStart(StatisticsPeriod.day, now), DateTime(2026, 8, 19));
  });
  test('only owners manage a family',(){expect(const FamilyPermissions(FamilyRole.owner).canManageFamily,isTrue);expect(const FamilyPermissions(FamilyRole.caregiver).canManageFamily,isFalse);expect(const FamilyPermissions(FamilyRole.caregiver).canRecordEvents,isTrue);});
  test('a persisted session skips login',(){expect(authRedirect(signedIn:true,location:'/login'),'/home');expect(authRedirect(signedIn:true,location:'/home'),isNull);expect(authRedirect(signedIn:false,location:'/home'),'/login');});
}
