import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../../babies/domain/baby.dart';

class FamilyRepository {
  FamilyRepository(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Stream<String?> watchCurrentFamilyId() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);
    return _firestore.collection('users').doc(user.uid).snapshots().map(
          (snapshot) => snapshot.data()?['familyId'] as String?,
        );
  }

  Stream<List<Baby>> watchBabies(String familyId) => _firestore
      .collection('families')
      .doc(familyId)
      .collection('babies')
      .orderBy('createdAt')
      .snapshots(includeMetadataChanges: true)
      .map(
        (snapshot) => snapshot.docs
            .map((document) => Baby.fromFirestore(document.id, document.data()))
            .toList(),
      );

  Future<String> createFamily({
    required String name,
    required List<({String name, DateTime dateOfBirth})> babies,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('A signed-in user is required.');
    if (babies.isEmpty) throw ArgumentError('Add at least one baby.');

    final family = _firestore.collection('families').doc();
    final batch = _firestore.batch();
    final now = DateTime.now().toUtc();
    final inviteCode = (100000 + Random.secure().nextInt(900000)).toString();

    batch.set(family, {
      'name': name.trim(),
      'inviteCode': inviteCode,
      'createdBy': user.uid,
      'createdAt': Timestamp.fromDate(now),
    });
    batch.set(family.collection('members').doc(user.uid), {
      'userId': user.uid,
      'displayName': user.displayName ?? user.email ?? 'Owner',
      'role': 'owner',
      'joinedAt': Timestamp.fromDate(now),
    });
    batch.set(_firestore.collection('users').doc(user.uid), {
      'email': user.email,
      'displayName': user.displayName,
      'familyId': family.id,
      'updatedAt': Timestamp.fromDate(now),
    }, SetOptions(merge: true));

    for (final input in babies) {
      final id = const Uuid().v4();
      final baby = Baby(
        id: id,
        familyId: family.id,
        name: input.name.trim(),
        dateOfBirth: input.dateOfBirth,
        createdAt: now,
        createdBy: user.uid,
      );
      batch.set(family.collection('babies').doc(id), baby.toFirestore());
    }
    await batch.commit();
    return family.id;
  }

  Future<void> updateBaby(Baby baby) => _firestore
      .collection('families')
      .doc(baby.familyId)
      .collection('babies')
      .doc(baby.id)
      .set(baby.toFirestore(), SetOptions(merge: true));

  Future<void> addBaby({
    required String familyId,
    required String name,
    required DateTime dateOfBirth,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('A signed-in user is required.');
    final id = const Uuid().v4();
    final baby = Baby(
      id: id,
      familyId: familyId,
      name: name.trim(),
      dateOfBirth: dateOfBirth,
      createdAt: DateTime.now().toUtc(),
      createdBy: user.uid,
    );
    await _firestore
        .collection('families')
        .doc(familyId)
        .collection('babies')
        .doc(id)
        .set(baby.toFirestore());
  }
}
