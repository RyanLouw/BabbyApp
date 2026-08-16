import '../../events/domain/baby_event.dart';
class CareStatistics {
  CareStatistics(List<BabyEvent> source, DateTime from) : events = source.where((e) => !e.start.isBefore(from)).toList();
  final List<BabyEvent> events;
  Iterable<BabyEvent> get feeds => events.where((e) => e.type == BabyEventType.feeding);
  Iterable<BabyEvent> get bottleFeeds => feeds.where((e) => e.data['amountMl'] is num);
  int get feedCount => feeds.length;
  int get totalMl => bottleFeeds.fold(0, (n, e) => n + (e.data['amountMl']! as num).round());
  double get averageBottleMl => bottleFeeds.isEmpty ? 0 : totalMl / bottleFeeds.length;
  Iterable<BabyEvent> get sleeps => events.where((e) => e.type == BabyEventType.sleep && e.end != null);
  Duration get totalSleep => sleeps.fold(Duration.zero, (d, e) => d + e.duration());
  int get sleepSessionCount => sleeps.length;
  Duration get averageSleep => sleepSessionCount == 0 ? Duration.zero : Duration(microseconds: totalSleep.inMicroseconds ~/ sleepSessionCount);
  Iterable<BabyEvent> get nappyEvents => events.where((e) => e.type == BabyEventType.nappy);
  int get nappyCount => nappyEvents.length;
  int nappies(NappyType type) => events.where((e) => e.type == BabyEventType.nappy && e.data['kind'] == type.name).length;
}
