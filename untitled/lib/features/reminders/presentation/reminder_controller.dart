import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/reminder_notification_service.dart';
import '../data/reminder_repository.dart';
import '../domain/care_reminder.dart';

final reminderRepositoryProvider = Provider((_) => ReminderRepository());
final reminderNotificationServiceProvider = Provider(
  (_) => reminderNotificationService,
);

final reminderControllerProvider =
    AsyncNotifierProvider<ReminderController, List<CareReminder>>(
  ReminderController.new,
);

class ReminderController extends AsyncNotifier<List<CareReminder>> {
  @override
  Future<List<CareReminder>> build() =>
      ref.read(reminderRepositoryProvider).load();

  Future<bool> add(CareReminderType type, int hour, int minute) async {
    final service = ref.read(reminderNotificationServiceProvider);
    if (!await service.requestPermission()) return false;
    final reminders = await _current();
    final reminder = CareReminder(
      id: DateTime.now().microsecondsSinceEpoch.remainder(0x7fffffff),
      type: type,
      hour: hour,
      minute: minute,
    );
    final updated = [...reminders, reminder]..sort(_compare);
    await _store(updated);
    await service.schedule(reminder);
    state = AsyncData(updated);
    return true;
  }

  Future<void> setEnabled(CareReminder reminder, bool enabled) async {
    final updatedReminder = reminder.copyWith(enabled: enabled);
    final reminders = [
      for (final value in await _current())
        if (value.id == reminder.id) updatedReminder else value,
    ];
    await _store(reminders);
    final service = ref.read(reminderNotificationServiceProvider);
    if (enabled) {
      await service.schedule(updatedReminder);
    } else {
      await service.cancel(reminder.id);
    }
    state = AsyncData(reminders);
  }

  Future<void> remove(CareReminder reminder) async {
    final reminders = [
      for (final value in await _current())
        if (value.id != reminder.id) value,
    ];
    await _store(reminders);
    await ref.read(reminderNotificationServiceProvider).cancel(reminder.id);
    state = AsyncData(reminders);
  }

  Future<void> _store(List<CareReminder> reminders) =>
      ref.read(reminderRepositoryProvider).save(reminders);

  Future<List<CareReminder>> _current() async =>
      state.value ?? await ref.read(reminderRepositoryProvider).load();

  static int _compare(CareReminder first, CareReminder second) =>
      (first.hour * 60 + first.minute).compareTo(
        second.hour * 60 + second.minute,
      );
}
