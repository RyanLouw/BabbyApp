import 'package:flutter/material.dart';

import '../../events/domain/baby_event.dart';
import '../domain/care_statistics.dart';

enum StatisticsPeriod {
  today('Today', 1),
  sevenDays('7 days', 7),
  thirtyDays('30 days', 30);

  const StatisticsPeriod(this.label, this.days);

  final String label;
  final int days;
}

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({
    super.key,
    this.events = const [],
    this.babyName = 'All babies',
  });

  final List<BabyEvent> events;
  final String babyName;

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  StatisticsPeriod _period = StatisticsPeriod.today;

  DateTime _startOfPeriod(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return today.subtract(Duration(days: _period.days - 1));
  }

  @override
  Widget build(BuildContext context) {
    final statistics = CareStatistics(
      widget.events,
      _startOfPeriod(DateTime.now()),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<StatisticsPeriod>(
            segments: StatisticsPeriod.values
                .map(
                  (period) => ButtonSegment<StatisticsPeriod>(
                    value: period,
                    label: Text(period.label),
                  ),
                )
                .toList(),
            selected: {_period},
            showSelectedIcon: false,
            onSelectionChanged: (selection) {
              setState(() => _period = selection.first);
            },
          ),
          const SizedBox(height: 20),
          Text(
            '${widget.babyName} — ${_period.label}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          _StatisticCard(
            title: 'Feeding',
            icon: Icons.local_drink,
            lines: [
              '${statistics.feedCount} feeds',
              '${statistics.totalMl} ml total',
              '${statistics.averageBottleMl.round()} ml average per bottle',
            ],
          ),
          _StatisticCard(
            title: 'Sleep',
            icon: Icons.bedtime,
            lines: [
              _formatDuration(statistics.totalSleep),
              '${statistics.sleepSessionCount} sessions',
              '${_formatDuration(statistics.averageSleep)} average',
            ],
          ),
          _StatisticCard(
            title: 'Nappies',
            icon: Icons.baby_changing_station,
            lines: [
              'Wet: ${statistics.nappies(NappyType.wet)}',
              'Dirty: ${statistics.nappies(NappyType.dirty)}',
              'Both: ${statistics.nappies(NappyType.both)}',
              'Total: ${statistics.nappyCount}',
            ],
          ),
        ],
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  return hours == 0 ? '${minutes}m' : '${hours}h ${minutes}m';
}

class _StatisticCard extends StatelessWidget {
  const _StatisticCard({
    required this.title,
    required this.icon,
    required this.lines,
  });

  final String title;
  final IconData icon;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, semanticLabel: title),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...lines.map(Text.new),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
