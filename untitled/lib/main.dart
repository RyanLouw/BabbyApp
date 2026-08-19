import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'features/reminders/data/reminder_notification_service.dart';
import 'features/reminders/data/reminder_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  await reminderNotificationService.initialize();
  if (reminderNotificationService.isSupported) {
    for (final reminder in await ReminderRepository().load()) {
      if (reminder.enabled) {
        await reminderNotificationService.schedule(reminder);
      }
    }
  }
  runApp(const ProviderScope(child: NurtureNestApp()));
}
