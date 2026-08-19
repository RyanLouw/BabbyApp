import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../babies/domain/baby.dart';
import '../../events/domain/baby_event.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyId = ref.watch(currentFamilyIdProvider).value;
    if (familyId == null) {
      return const Scaffold(
        appBar: _HistoryAppBar(),
        body: _HistoryEmpty(),
      );
    }
    final babies = ref.watch(babiesProvider(familyId)).value ?? const <Baby>[];
    final names = {for (final baby in babies) baby.id: baby.name};
    final events = ref.watch(familyEventsProvider(familyId));
    return Scaffold(
      appBar: const _HistoryAppBar(),
      body: events.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Could not load history.')),
        data: (items) => items.isEmpty
            ? const _HistoryEmpty()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final event = items[index];
                  return _HistoryEntry(
                    event: event,
                    babyName: names[event.babyId] ?? 'Baby',
                  );
                },
              ),
      ),
    );
  }
}

class _HistoryAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _HistoryAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(title: const Text('History'));
}

class _HistoryEmpty extends StatelessWidget {
  const _HistoryEmpty();

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Nothing recorded yet.\n\nUse a baby’s Feed, Sleep, Nappy, or Note button to add the first event.',
            textAlign: TextAlign.center,
          ),
        ),
      );
}

class _HistoryEntry extends ConsumerWidget {
  const _HistoryEntry({required this.event, required this.babyName});

  final BabyEvent event;
  final String babyName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(child: Icon(_icon(event.type))),
        title: Text(_description(event)),
        subtitle: Text('${_dateAndTime(event.start)} · $babyName'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') _confirmDelete(context, ref);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this event?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(eventRepositoryProvider).deleteEvent(
          familyId: event.familyId,
          babyId: event.babyId,
          eventId: event.id,
        );
  }
}

String _description(BabyEvent event) => switch (event.type) {
      BabyEventType.feeding =>
        'Feed · ${event.data['amountMl'] ?? 0} ml ${_milk(event.data['milkType'])}',
      BabyEventType.sleep => event.end == null
          ? 'Sleep started'
          : 'Slept ${_duration(event.duration())}',
      BabyEventType.nappy => '${_capitalize(event.data['kind'])} nappy',
      BabyEventType.note => event.notes ?? 'Note',
      BabyEventType.growth => _growthDescription(event),
      _ => event.type.name,
    };
IconData _icon(BabyEventType type) => switch (type) {
      BabyEventType.feeding => Icons.local_drink,
      BabyEventType.sleep => Icons.bedtime,
      BabyEventType.nappy => Icons.baby_changing_station,
      BabyEventType.growth => Icons.monitor_weight_outlined,
      _ => Icons.note,
    };
String _dateAndTime(DateTime value) {
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/${local.year} · '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}
String _duration(Duration value) =>
    '${value.inHours}h ${value.inMinutes.remainder(60)}m';
String _capitalize(Object? value) {
  final text = value?.toString() ?? 'Changed';
  return '${text[0].toUpperCase()}${text.substring(1)}';
}
String _milk(Object? value) => switch (value) {
      'breastMilk' => 'Breast milk',
      'formula' => 'Formula',
      'other' => 'Other',
      _ => '',
    };

String _growthDescription(BabyEvent event) {
  final values = <String>[
    if (event.data['weightKg'] case final num weight) '$weight kg',
    if ((event.data['lengthCm'] ?? event.data['heightCm']) case final num length)
      '$length cm',
  ];
  return 'Growth · ${values.join(' · ')}';
}
