import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../babies/domain/baby.dart';
import '../../events/domain/baby_event.dart';
import '../domain/care_statistics.dart';

enum StatisticsPeriod {
  day('Day', 1),
  week('Week', 7),
  month('Month', 30),
  threeMonths('3 months', 90),
  sixMonths('6 months', 180),
  year('Year', 365);

  const StatisticsPeriod(this.label, this.days);
  final String label;
  final int days;
}

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  StatisticsPeriod _period = StatisticsPeriod.week;
  String? _babyId;

  @override
  Widget build(BuildContext context) {
    final familyId = ref.watch(currentFamilyIdProvider).value;
    if (familyId == null) {
      return const Scaffold(body: Center(child: Text('Create a family first.')));
    }
    final babies = ref.watch(babiesProvider(familyId)).value ?? const <Baby>[];
    final eventsValue = ref.watch(familyEventsProvider(familyId));
    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: eventsValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Could not load statistics.')),
        data: (allEvents) {
          final events = _babyId == null
              ? allEvents
              : allEvents.where((event) => event.babyId == _babyId).toList();
          final from = DateTime.now().subtract(Duration(days: _period.days));
          final statistics = CareStatistics(events, from);
          final baby = _selectedBaby(babies);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<String?>(
                initialValue: _babyId,
                decoration: const InputDecoration(labelText: 'Show statistics for'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Whole family')),
                  ...babies.map(
                    (baby) => DropdownMenuItem(
                      value: baby.id,
                      child: Text(baby.name),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _babyId = value),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<StatisticsPeriod>(
                  segments: StatisticsPeriod.values
                      .map(
                        (period) => ButtonSegment(
                          value: period,
                          label: Text(period.label),
                        ),
                      )
                      .toList(),
                  selected: {_period},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) =>
                      setState(() => _period = selection.first),
                ),
              ),
              const SizedBox(height: 20),
              _CareOverview(statistics: statistics),
              const SizedBox(height: 20),
              if (baby == null)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Choose one baby above to see weight and height changes.',
                    ),
                  ),
                )
              else
                _GrowthSection(events: statistics.events, baby: baby),
            ],
          );
        },
      ),
    );
  }

  Baby? _selectedBaby(List<Baby> babies) {
    for (final baby in babies) {
      if (baby.id == _babyId) return baby;
    }
    return null;
  }
}

class _CareOverview extends StatelessWidget {
  const _CareOverview({required this.statistics});
  final CareStatistics statistics;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MetricCard(
          title: 'Feeding',
          icon: Icons.local_drink,
          value: '${statistics.totalMl} ml',
          detail: '${statistics.feedCount} feeds · '
              '${statistics.averageBottleMl.round()} ml average',
        ),
        _MetricCard(
          title: 'Sleep',
          icon: Icons.bedtime,
          value: _duration(statistics.totalSleep),
          detail: '${statistics.sleepSessionCount} sessions · '
              '${_duration(statistics.averageSleep)} average',
        ),
        _MetricCard(
          title: 'Nappies',
          icon: Icons.baby_changing_station,
          value: '${statistics.nappyCount} changes',
          detail: 'Wet ${statistics.nappies(NappyType.wet)}  ·  '
              'Dirty ${statistics.nappies(NappyType.dirty)}  ·  '
              'Both ${statistics.nappies(NappyType.both)}',
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.icon,
    required this.value,
    required this.detail,
  });
  final String title, value, detail;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon),
                  const SizedBox(width: 10),
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  Text(value, style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: Theme.of(context).colorScheme.primary),
              Text(detail),
            ],
          ),
        ),
      );
}

class _GrowthSection extends StatelessWidget {
  const _GrowthSection({required this.events, required this.baby});
  final List<BabyEvent> events;
  final Baby baby;

  @override
  Widget build(BuildContext context) {
    final growth = events.where((event) => event.type == BabyEventType.growth).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    final weights = _points(growth, 'weightKg');
    final heights = _points(growth, 'heightCm');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${baby.name} growth', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        _GrowthCard(title: 'Weight', unit: 'kg', points: weights),
        _GrowthCard(title: 'Height', unit: 'cm', points: heights),
      ],
    );
  }
}

List<double> _points(List<BabyEvent> events, String field) => events
    .map((event) => event.data[field])
    .whereType<num>()
    .map((value) => value.toDouble())
    .toList();

class _GrowthCard extends StatelessWidget {
  const _GrowthCard({required this.title, required this.unit, required this.points});
  final String title, unit;
  final List<double> points;

  @override
  Widget build(BuildContext context) {
    final change = points.length < 2 ? null : points.last - points.first;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (points.isNotEmpty) Text('${points.last.toStringAsFixed(2)} $unit'),
              ],
            ),
            const SizedBox(height: 12),
            if (points.isEmpty)
              const Text('No measurements in this period.')
            else ...[
              SizedBox(
                height: 130,
                width: double.infinity,
                child: CustomPaint(
                  painter: _LineChartPainter(
                    points: points,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              Text(
                change == null
                    ? 'Add another measurement to show change.'
                    : '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)} $unit in this period',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter({required this.points, required this.color});
  final List<double> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final minValue = points.reduce(math.min);
    final maxValue = points.reduce(math.max);
    final range = math.max(0.01, maxValue - minValue);
    final line = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = color;
    final path = Path();
    for (var index = 0; index < points.length; index++) {
      final x = points.length == 1 ? size.width / 2 : size.width * index / (points.length - 1);
      final y = size.height - ((points[index] - minValue) / range * (size.height - 20)) - 10;
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 4, fill);
    }
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(_LineChartPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.color != color;
}

String _duration(Duration duration) =>
    '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
