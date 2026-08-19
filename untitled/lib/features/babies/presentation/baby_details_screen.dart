import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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
  bool _uploadingImage = false;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.baby.name);
    _profileImageUrl = widget.baby.profileImageUrl;
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
      profileImageUrl: _profileImageUrl,
    );
    await ref.read(familyRepositoryProvider).updateBaby(baby);
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _chooseProfileImage() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1200,
    );
    if (image == null) return;
    setState(() => _uploadingImage = true);
    try {
      final Uint8List bytes = await image.readAsBytes();
      final reference = FirebaseStorage.instance.ref(
        'families/${widget.baby.familyId}/babies/${widget.baby.id}/profile.jpg',
      );
      await reference.putData(
        bytes,
        SettableMetadata(contentType: image.mimeType ?? 'image/jpeg'),
      );
      final url = await reference.getDownloadURL();
      final updated = Baby(
        id: widget.baby.id,
        familyId: widget.baby.familyId,
        name: _name.text.trim().isEmpty ? widget.baby.name : _name.text.trim(),
        dateOfBirth: widget.baby.dateOfBirth,
        createdAt: widget.baby.createdAt,
        createdBy: widget.baby.createdBy,
        profileImageUrl: url,
      );
      await ref.read(familyRepositoryProvider).updateBaby(updated);
      if (mounted) {
        setState(() => _profileImageUrl = url);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated.')),
        );
      }
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not upload the photo. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
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
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundImage: _profileImageUrl == null
                      ? null
                      : NetworkImage(_profileImageUrl!),
                  child: _profileImageUrl == null
                      ? Text(widget.baby.name.characters.first,
                          style: Theme.of(context).textTheme.headlineMedium)
                      : null,
                ),
                IconButton.filled(
                  tooltip: 'Choose profile photo',
                  onPressed: _uploadingImage ? null : _chooseProfileImage,
                  icon: _uploadingImage
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_a_photo_outlined),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
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
