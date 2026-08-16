import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';

class CreateFamilyScreen extends ConsumerStatefulWidget {
  const CreateFamilyScreen({super.key});

  @override
  ConsumerState<CreateFamilyScreen> createState() => _CreateFamilyScreenState();
}

class _CreateFamilyScreenState extends ConsumerState<CreateFamilyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _familyName = TextEditingController();
  final List<TextEditingController> _babyNames = [
    TextEditingController(),
    TextEditingController(),
  ];
  final List<DateTime> _birthDates = [DateTime.now(), DateTime.now()];
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _familyName.dispose();
    for (final controller in _babyNames) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addBaby() {
    setState(() {
      _babyNames.add(TextEditingController());
      _birthDates.add(DateTime.now());
    });
  }

  Future<void> _chooseBirthDate(int index) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _birthDates[index],
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select date of birth',
    );
    if (selected != null) setState(() => _birthDates[index] = selected);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(familyRepositoryProvider).createFamily(
            name: _familyName.text,
            babies: [
              for (var i = 0; i < _babyNames.length; i++)
                (name: _babyNames[i].text, dateOfBirth: _birthDates[i]),
            ],
          );
    } on Exception {
      if (mounted) {
        setState(() => _error = 'We could not save your family. Try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set up your family')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Add your babies',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text('Their real details will appear on the shared dashboard.'),
            const SizedBox(height: 24),
            TextFormField(
              controller: _familyName,
              decoration: const InputDecoration(
                labelText: 'Family name',
                hintText: 'Louw Family',
              ),
              validator: _required,
            ),
            const SizedBox(height: 24),
            for (var index = 0; index < _babyNames.length; index++) ...[
              TextFormField(
                controller: _babyNames[index],
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Baby ${index + 1} name',
                  prefixIcon: const Icon(Icons.child_care),
                ),
                validator: _required,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _chooseBirthDate(index),
                icon: const Icon(Icons.cake_outlined),
                label: Text('Born ${_formatDate(_birthDates[index])}'),
              ),
              const SizedBox(height: 20),
            ],
            TextButton.icon(
              onPressed: _addBaby,
              icon: const Icon(Icons.add),
              label: const Text('Add another baby'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const CircularProgressIndicator()
                  : const Text('Create family'),
            ),
          ],
        ),
      ),
    );
  }

  static String? _required(String? value) => value?.trim().isEmpty ?? true
      ? 'This field is required.'
      : null;

  static String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';
}
