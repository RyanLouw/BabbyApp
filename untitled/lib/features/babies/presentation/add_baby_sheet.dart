import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';

class AddBabySheet extends ConsumerStatefulWidget {
  const AddBabySheet({super.key, required this.familyId});
  final String familyId;

  @override
  ConsumerState<AddBabySheet> createState() => _AddBabySheetState();
}

class _AddBabySheetState extends ConsumerState<AddBabySheet> {
  final _name = TextEditingController();
  DateTime _dateOfBirth = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select date of birth',
    );
    if (selected != null) setState(() => _dateOfBirth = selected);
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the baby’s name.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(familyRepositoryProvider).addBaby(
            familyId: widget.familyId,
            name: _name.text,
            dateOfBirth: _dateOfBirth,
          );
      if (mounted) Navigator.pop(context);
    } on Exception {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            20 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add another baby', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              TextField(
                controller: _name,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Baby name'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _chooseDate,
                icon: const Icon(Icons.cake_outlined),
                label: Text(
                  'Born ${_dateOfBirth.day}/${_dateOfBirth.month}/${_dateOfBirth.year}',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const CircularProgressIndicator()
                    : const Text('Add baby'),
              ),
            ],
          ),
        ),
      );
}
