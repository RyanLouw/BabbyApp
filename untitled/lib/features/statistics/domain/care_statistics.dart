import '../../events/domain/baby_event.dart';
class CareStatistics {
  CareStatistics(List<BabyEvent> source, DateTime from) : events = source.where((e) => !e.start.isBefore(from)).toList();
  final List<BabyEvent> events;
  Iterable<BabyEvent> get feeds => events.where((e) => e.type == BabyEventType.feeding);
  int get feedCount => feeds.length;
  int get totalMl => feeds.fold(0, (n, e) => n + ((e.data['amountMl'] as num?)?.round() ?? 0));
  double get averageBottleMl => feedCount == 0 ? 0 : totalMl / feedCount;
  Iterable<BabyEvent> get sleeps => events.where((e) => e.type == BabyEventType.sleep && e.end != null);
  Duration get totalSleep => sleeps.fold(Duration.zero, (d, e) => d + e.duration());
  int nappies(NappyType type) => events.where((e) => e.type == BabyEventType.nappy && e.data['kind'] == type.name).length;
}
