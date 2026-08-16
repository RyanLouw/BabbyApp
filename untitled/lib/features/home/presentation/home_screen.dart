import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/providers.dart';
import '../../babies/domain/baby.dart';
import '../../babies/presentation/baby_details_screen.dart';
import '../../events/presentation/record_event_sheet.dart';
import '../../events/domain/baby_event.dart';
import '../../family/presentation/create_family_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyId = ref.watch(currentFamilyIdProvider);
    return familyId.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => _LoadError(error: error),
      data: (id) {
        if (id == null) return const CreateFamilyScreen();
        return _FamilyHome(familyId: id);
      },
    );
  }
}

class _FamilyHome extends ConsumerWidget {
  const _FamilyHome({required this.familyId});

  final String familyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final babies = ref.watch(babiesProvider(familyId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your babies'),
        actions: const [
        ],
      ),
      body: babies.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _LoadError(error: error),
        data: (items) => items.isEmpty
            ? const _NoBabies()
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'What’s happening right now?',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cardWidth = constraints.maxWidth > 650
                          ? (constraints.maxWidth - 16) / 2
                          : constraints.maxWidth;
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: items
                            .map(
                              (baby) => _BabyCard(
                                baby: baby,
                                width: cardWidth,
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 100),
                ],
              ),
      ),
    );
  }
}

class _BabyCard extends ConsumerWidget {
  const _BabyCard({required this.baby, required this.width});

  final Baby baby;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(babyEventsProvider((
      familyId: baby.familyId,
      babyId: baby.id,
    )));
    final items = events.value ?? const <BabyEvent>[];
    final lastFeed = _firstOfType(items, BabyEventType.feeding);
    final lastNappy = _firstOfType(items, BabyEventType.nappy);
    final activeSleep = _activeSleep(items);
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => BabyDetailsScreen(baby: baby),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      CircleAvatar(child: Text(baby.name.characters.first)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          baby.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _Status(
                Icons.local_drink_outlined,
                lastFeed == null
                    ? 'No feeds yet'
                    : '${lastFeed.data['amountMl']} ml · ${_ago(lastFeed.start)}',
              ),
              _Status(
                Icons.bedtime_outlined,
                activeSleep == null
                    ? 'Awake'
                    : 'Sleeping · ${_duration(activeSleep.duration())}',
              ),
              _Status(
                Icons.baby_changing_station,
                lastNappy == null
                    ? 'No nappies yet'
                    : '${_capitalized(lastNappy.data['kind'] as String?)} · ${_ago(lastNappy.start)}',
              ),
              const Divider(height: 28),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _action(context, 'Feed', BabyEventType.feeding),
                  if (activeSleep == null)
                    _action(context, 'Start sleep', BabyEventType.sleep)
                  else
                    FilledButton.tonal(
                      onPressed: () => _wakeUp(context, ref, activeSleep),
                      child: const Text('Wake up'),
                    ),
                  _action(context, 'Nappy', BabyEventType.nappy),
                  _action(context, 'Note', BabyEventType.note),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _action(BuildContext context, String label, BabyEventType type) {
    return FilledButton.tonal(
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => RecordEventSheet(
          familyId: baby.familyId,
          baby: baby,
          initialType: type,
        ),
      ),
      child: Text(label),
    );
  }

  Future<void> _wakeUp(
    BuildContext context,
    WidgetRef ref,
    BabyEvent sleep,
  ) async {
    final now = DateTime.now().toUtc();
    final updated = BabyEvent(
      id: sleep.id,
      familyId: sleep.familyId,
      babyId: sleep.babyId,
      type: sleep.type,
      start: sleep.start,
      end: now,
      createdAt: sleep.createdAt,
      createdBy: sleep.createdBy,
      updatedAt: now,
      updatedBy: FirebaseAuth.instance.currentUser!.uid,
      notes: sleep.notes,
      data: sleep.data,
    );
    await ref.read(eventRepositoryProvider).updateEvent(updated);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${baby.name} woke up')),
      );
    }
  }
}

class _Status extends StatelessWidget {
  const _Status(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon),
        title: Text(label),
        dense: true,
      );
}

class _NoBabies extends StatelessWidget {
  const _NoBabies();

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No babies added yet. Add a baby in Settings.'),
        ),
      );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final permissionDenied = error.toString().contains('permission-denied') ||
        error.toString().contains('PERMISSION_DENIED');
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            permissionDenied
                ? 'Firebase access is not configured yet. Ask the family owner '
                    'to deploy the Firestore security rules, then try again.'
                : 'We could not load your family. Please try again.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

BabyEvent? _firstOfType(List<BabyEvent> events, BabyEventType type) {
  for (final event in events) {
    if (event.type == type) return event;
  }
  return null;
}

BabyEvent? _activeSleep(List<BabyEvent> events) {
  for (final event in events) {
    if (event.type == BabyEventType.sleep && event.end == null) return event;
  }
  return null;
}

String _ago(DateTime time) {
  final elapsed = DateTime.now().difference(time.toLocal());
  if (elapsed.inMinutes < 1) return 'just now';
  if (elapsed.inHours < 1) return '${elapsed.inMinutes}m ago';
  return '${elapsed.inHours}h ${elapsed.inMinutes.remainder(60)}m ago';
}

String _duration(Duration duration) {
  if (duration.inHours < 1) return '${duration.inMinutes}m';
  return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
}

String _capitalized(String? value) {
  if (value == null || value.isEmpty) return 'Nappy';
  return '${value[0].toUpperCase()}${value.substring(1)}';
}
