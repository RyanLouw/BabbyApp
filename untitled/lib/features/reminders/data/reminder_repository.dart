import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/care_reminder.dart';

class ReminderRepository {
  static const _storageKey = 'care_reminders_v1';

  Future<List<CareReminder>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_storageKey);
    if (encoded == null) return [];
    final values = jsonDecode(encoded) as List<dynamic>;
    return values
        .map((value) => CareReminder.fromJson(value as Map<String, dynamic>))
        .toList()
      ..sort(_compare);
  }

  Future<void> save(List<CareReminder> reminders) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      jsonEncode(reminders.map((reminder) => reminder.toJson()).toList()),
    );
  }

  static int _compare(CareReminder first, CareReminder second) =>
      (first.hour * 60 + first.minute).compareTo(
        second.hour * 60 + second.minute,
      );
}
