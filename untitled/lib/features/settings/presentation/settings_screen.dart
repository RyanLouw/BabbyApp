import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app.dart';
import '../../../core/providers.dart';
import '../../babies/presentation/baby_details_screen.dart';
import '../../babies/presentation/add_baby_sheet.dart';
import '../../reminders/domain/care_reminder.dart';
import '../../reminders/presentation/reminder_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyId = ref.watch(currentFamilyIdProvider).value;
    final babies = familyId == null
        ? null
        : ref.watch(babiesProvider(familyId)).value;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _Header('Babies'),
          if (babies == null)
            const ListTile(title: Text('Loading babies…'))
          else
            for (final baby in babies)
              ListTile(
                leading: const Icon(Icons.child_care),
                title: Text(baby.name),
                subtitle: const Text('Details, weight and length'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => BabyDetailsScreen(baby: baby),
                  ),
                ),
              ),
          if (familyId != null)
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Add another baby'),
              onTap: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (_) => AddBabySheet(familyId: familyId),
              ),
            ),
          const Divider(),
          const _Header('Care schedule'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Get a daily sound and vibration at each selected feeding or sleep time, even when the app is closed.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          ref.watch(reminderControllerProvider).when(
                loading: () => const ListTile(
                  leading: CircularProgressIndicator(),
                  title: Text('Loading schedule…'),
                ),
                error: (error, _) => ListTile(
                  leading: const Icon(Icons.error_outline),
                  title: const Text('Could not load the schedule'),
                  subtitle: Text('$error'),
                ),
                data: (reminders) => Column(
                  children: [
                    for (final reminder in reminders)
                      _ReminderTile(reminder: reminder),
                    if (reminders.isEmpty)
                      const ListTile(
                        leading: Icon(Icons.notifications_none),
                        title: Text('No reminders yet'),
                        subtitle: Text('Add as many daily times as you need.'),
                      ),
                  ],
                ),
              ),
          ListTile(
            leading: const Icon(Icons.add_alarm),
            title: const Text('Add reminder time'),
            subtitle: const Text('Choose feeding or sleep and select a time'),
            onTap: () => _addReminder(context, ref),
          ),
          const Divider(),
          const _Header('Appearance'),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('Theme'),
            trailing: DropdownButton<ThemeMode>(
              value: ref.watch(themeModeProvider),
              items: ThemeMode.values
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(value.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeModeProvider.notifier).select(value);
                }
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              await ref.read(authRepositoryProvider).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }

  Future<void> _addReminder(BuildContext context, WidgetRef ref) async {
    final type = await showModalBottomSheet<CareReminderType>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('What is this reminder for?')),
            for (final value in CareReminderType.values)
              ListTile(
                leading: Icon(
                  value == CareReminderType.feeding
                      ? Icons.restaurant
                      : Icons.bedtime_outlined,
                ),
                title: Text(value.label),
                onTap: () => Navigator.pop(context, value),
              ),
          ],
        ),
      ),
    );
    if (type == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Choose daily ${type.label.toLowerCase()} time',
    );
    if (time == null) return;
    final added = await ref
        .read(reminderControllerProvider.notifier)
        .add(type, time.hour, time.minute);
    if (!added && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Notifications and exact alarms must be allowed for reminders.',
          ),
        ),
      );
    }
  }
}

class _ReminderTile extends ConsumerWidget {
  const _ReminderTile({required this.reminder});

  final CareReminder reminder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final time = TimeOfDay(hour: reminder.hour, minute: reminder.minute);
    return ListTile(
      leading: Icon(
        reminder.type == CareReminderType.feeding
            ? Icons.restaurant
            : Icons.bedtime_outlined,
      ),
      title: Text(reminder.type.label),
      subtitle: Text(time.format(context)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: reminder.enabled,
            onChanged: (enabled) => ref
                .read(reminderControllerProvider.notifier)
                .setEnabled(reminder, enabled),
          ),
          IconButton(
            tooltip: 'Delete reminder',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => ref
                .read(reminderControllerProvider.notifier)
                .remove(reminder),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Text(label, style: Theme.of(context).textTheme.titleMedium),
      );
}
