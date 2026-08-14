import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/events/data/firestore_event_repository.dart';
import '../features/events/domain/event_repository.dart';
final authRepositoryProvider = Provider((ref) => AuthRepository(FirebaseAuth.instance));
final authStateProvider = StreamProvider((ref) => ref.watch(authRepositoryProvider).watch());
final eventRepositoryProvider = Provider<BabyEventRepository>((ref) => FirestoreBabyEventRepository(FirebaseFirestore.instance));
