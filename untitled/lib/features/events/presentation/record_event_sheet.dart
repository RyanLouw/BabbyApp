import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers.dart';
import '../../babies/domain/baby.dart';
import '../domain/baby_event.dart';

class RecordEventSheet extends ConsumerStatefulWidget {
  const RecordEventSheet({
    super.key,
    this.familyId,
    this.baby,
    this.initialType,
  });

  final String? familyId;
  final Baby? baby;
  final BabyEventType? initialType;

  @override
  ConsumerState<RecordEventSheet> createState() => _RecordEventSheetState();
}

class _RecordEventSheetState extends ConsumerState<RecordEventSheet> {
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  BabyEventType? _type;
  MilkType _milk = MilkType.formula;
  NappyType _nappy = NappyType.wet;
  DateTime _time = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _changeTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _time,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_time),
    );
    if (time == null) return;
    setState(() {
      _time = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    final type = _type;
    final baby = widget.baby;
    final familyId = widget.familyId;
    final user = FirebaseAuth.instance.currentUser;
    if (type == null || baby == null || familyId == null || user == null) return;
    final amount = int.tryParse(_amount.text);
    if (type == BabyEventType.feeding && (amount == null || amount <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the amount eaten in ml.')),
      );
      return;
    }
    if (type == BabyEventType.note && _notes.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write the note before saving.')),
      );
      return;
    }

    setState(() => _saving = true);
    final now = DateTime.now().toUtc();
    final data = <String, Object?>{
      if (type == BabyEventType.feeding) ...{
        'kind': 'bottle',
        'amountMl': amount,
        'milkType': _milk.name,
      },
      if (type == BabyEventType.nappy) 'kind': _nappy.name,
    };
    final event = BabyEvent(
      id: const Uuid().v4(),
      familyId: familyId,
      babyId: baby.id,
      type: type,
      start: _time.toUtc(),
      createdAt: now,
      createdBy: user.uid,
      updatedAt: now,
      updatedBy: user.uid,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      data: data,
    );
    try {
      await ref.read(eventRepositoryProvider).createEvent(event);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${baby.name} — ${_successLabel(type)} recorded'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () => ref.read(eventRepositoryProvider).deleteEvent(
                  familyId: familyId,
                  babyId: baby.id,
                  eventId: event.id,
                ),
          ),
        ),
      );
    } on Exception {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.baby == null || widget.familyId == null) {
      return const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Choose a baby on Home before recording an event.'),
        ),
      );
    }
    if (_type == null) return _typePicker(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${_title(_type!)} — ${widget.baby!.name}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 18),
            if (_type == BabyEventType.feeding) ...[
              TextField(
                controller: _amount,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Amount eaten',
                  suffixText: 'ml',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<MilkType>(
                initialValue: _milk,
                decoration: const InputDecoration(labelText: 'Milk type'),
                items: MilkType.values
                    .map((value) => DropdownMenuItem(
                          value: value,
                          child: Text(_milkLabel(value)),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _milk = value!),
              ),
            ],
            if (_type == BabyEventType.nappy)
              SegmentedButton<NappyType>(
                segments: NappyType.values
                    .map((value) => ButtonSegment(
                          value: value,
                          label: Text(_nappyLabel(value)),
                        ))
                    .toList(),
                selected: {_nappy},
                onSelectionChanged: (value) =>
                    setState(() => _nappy = value.first),
              ),
            if (_type == BabyEventType.sleep)
              const Text('Set when sleep started. Leave it running until Wake up.'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _changeTime,
              icon: const Icon(Icons.schedule),
              label: Text('Time: ${_formatTime(_time)}'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              minLines: 1,
              maxLines: 3,
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const CircularProgressIndicator()
                  : Text(_type == BabyEventType.sleep ? 'Start sleep' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typePicker(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'What happened?',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              for (final type in const [
                BabyEventType.feeding,
                BabyEventType.sleep,
                BabyEventType.nappy,
                BabyEventType.note,
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FilledButton.tonal(
                    onPressed: () => setState(() => _type = type),
                    child: Text(_title(type)),
                  ),
                ),
            ],
          ),
        ),
      );
}

String _title(BabyEventType type) => switch (type) {
      BabyEventType.feeding => 'Feed',
      BabyEventType.sleep => 'Sleep',
      BabyEventType.nappy => 'Nappy',
      BabyEventType.note => 'Note',
      _ => type.name,
    };
String _successLabel(BabyEventType type) => type == BabyEventType.sleep
    ? 'sleep started'
    : _title(type).toLowerCase();
String _milkLabel(MilkType value) => switch (value) {
      MilkType.formula => 'Formula',
      MilkType.breastMilk => 'Breast milk',
      MilkType.other => 'Other',
    };
String _nappyLabel(NappyType value) => switch (value) {
      NappyType.wet => 'Wet',
      NappyType.dirty => 'Dirty',
      NappyType.both => 'Both',
    };
String _formatTime(DateTime value) =>
    '${value.day}/${value.month} ${value.hour.toString().padLeft(2, '0')}:'
    '${value.minute.toString().padLeft(2, '0')}';
