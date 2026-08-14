import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers.dart';
import '../../events/domain/baby_event.dart';
import '../domain/baby.dart';

class BabyDetailsScreen extends ConsumerStatefulWidget {
  const BabyDetailsScreen({super.key, required this.baby});

  final Baby baby;

  @override
  ConsumerState<BabyDetailsScreen> createState() => _BabyDetailsScreenState();
}

class _BabyDetailsScreenState extends ConsumerState<BabyDetailsScreen> {
  late final TextEditingController _name;
  final _weight = TextEditingController();
  final _length = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.baby.name);
  }

  @override
  void dispose() {
    _name.dispose();
    _weight.dispose();
    _length.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final baby = Baby(
      id: widget.baby.id,
      familyId: widget.baby.familyId,
      name: _name.text.trim(),
      dateOfBirth: widget.baby.dateOfBirth,
      createdAt: widget.baby.createdAt,
      createdBy: widget.baby.createdBy,
      profileImage: widget.baby.profileImage,
    );
    await ref.read(familyRepositoryProvider).updateBaby(baby);
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _saveMeasurement() async {
    final weight = double.tryParse(_weight.text.replaceAll(',', '.'));
    final length = double.tryParse(_length.text.replaceAll(',', '.'));
    if ((weight == null || weight <= 0) && (length == null || length <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a weight or length.')),
      );
      return;
    }
    final user = FirebaseAuth.instance.currentUser!;
    final now = DateTime.now().toUtc();
    await ref.read(eventRepositoryProvider).createEvent(
          BabyEvent(
            id: const Uuid().v4(),
            familyId: widget.baby.familyId,
            babyId: widget.baby.id,
            type: BabyEventType.growth,
            start: now,
            createdAt: now,
            createdBy: user.uid,
            updatedAt: now,
            updatedBy: user.uid,
            data: {
              if (weight != null && weight > 0) 'weightKg': weight,
              if (length != null && length > 0) 'lengthCm': length,
            },
          ),
        );
    _weight.clear();
    _length.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Growth measurement saved.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.baby.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Baby details', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _saving ? null : _saveProfile,
            child: const Text('Save details'),
          ),
          const SizedBox(height: 32),
          Text(
            'Record growth',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('Add either value or both. Measurements use the current time.'),
          const SizedBox(height: 16),
          TextField(
            controller: _weight,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Weight',
              suffixText: 'kg',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _length,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Length',
              suffixText: 'cm',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _saveMeasurement,
            icon: const Icon(Icons.monitor_weight_outlined),
            label: const Text('Save measurement'),
          ),
        ],
      ),
    );
  }
}
