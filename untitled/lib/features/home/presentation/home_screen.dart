import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../babies/domain/baby.dart';
import '../../events/presentation/record_event_sheet.dart';
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
      error: (_, __) => const _LoadError(),
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
          Padding(
            padding: EdgeInsets.all(16),
            child: Chip(
              avatar: Icon(Icons.cloud_done, size: 16),
              label: Text('Synced'),
            ),
          ),
        ],
      ),
      body: babies.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const _LoadError(),
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

class _BabyCard extends StatelessWidget {
  const _BabyCard({required this.baby, required this.width});

  final Baby baby;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(child: Text(baby.name.characters.first)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      baby.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const _EmptyStatus(Icons.local_drink_outlined, 'No feeds yet'),
              const _EmptyStatus(Icons.bedtime_outlined, 'No sleep yet'),
              const _EmptyStatus(
                Icons.baby_changing_station,
                'No nappies yet',
              ),
              const Divider(height: 28),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Feed', 'Start sleep', 'Nappy']
                    .map(
                      (label) => FilledButton.tonal(
                        onPressed: () => showModalBottomSheet<void>(
                          context: context,
                          showDragHandle: true,
                          builder: (_) => const RecordEventSheet(),
                        ),
                        child: Text(label),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyStatus extends StatelessWidget {
  const _EmptyStatus(this.icon, this.label);

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
  const _LoadError();

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('We could not load your family. Please try again.'),
          ),
        ),
      );
}
