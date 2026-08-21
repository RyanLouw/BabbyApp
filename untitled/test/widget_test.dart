import 'package:babby_care/features/events/presentation/record_event_sheet.dart';
import 'package:babby_care/features/auth/presentation/auth_screen.dart';
import 'package:babby_care/core/providers.dart';
import 'package:babby_care/features/babies/domain/baby.dart';
import 'package:babby_care/features/babies/presentation/add_baby_sheet.dart';
import 'package:babby_care/features/events/domain/baby_event.dart';
import 'package:babby_care/features/events/domain/event_repository.dart';
import 'package:babby_care/features/history/presentation/history_screen.dart';
import 'package:babby_care/features/home/presentation/home_screen.dart';
import 'package:babby_care/features/statistics/presentation/statistics_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('dashboard shows both babies and current state', (tester) async {
    final now = DateTime(2026);
    final babies = [
      Baby(
        id: 'a',
        familyId: 'f',
        name: 'Amelia',
        dateOfBirth: now,
        createdAt: now,
        createdBy: 'u',
      ),
      Baby(
        id: 'b',
        familyId: 'f',
        name: 'Benjamin',
        dateOfBirth: now,
        createdAt: now,
        createdBy: 'u',
      ),
    ];
    final feed = BabyEvent(
      id: 'feed',
      familyId: 'f',
      babyId: 'a',
      type: BabyEventType.feeding,
      start: now,
      createdAt: now,
      createdBy: 'u',
      updatedAt: now,
      updatedBy: 'u',
      data: const {'amountMl': 120, 'milkType': 'formula'},
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentFamilyIdProvider.overrideWith((ref) => Stream.value('f')),
          babiesProvider('f').overrideWith((ref) => Stream.value(babies)),
          babyEventsProvider(
            (familyId: 'f', babyId: 'a'),
          ).overrideWith((ref) => Stream.value([feed])),
          babyEventsProvider(
            (familyId: 'f', babyId: 'b'),
          ).overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Amelia'), findsOneWidget);
    expect(find.text('Benjamin'), findsOneWidget);
    expect(find.textContaining('120 ml'), findsOneWidget);
    expect(find.text('No feeds yet'), findsOneWidget);
  });

  testWidgets('quick entry exposes common events', (tester) async {
    final now = DateTime(2026);
    final baby = Baby(
      id: 'a',
      familyId: 'f',
      name: 'Amelia',
      dateOfBirth: now,
      createdAt: now,
      createdBy: 'u',
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: RecordEventSheet(familyId: 'f', baby: baby),
          ),
        ),
      ),
    );

    expect(find.text('Feed'), findsOneWidget);
    expect(find.text('Sleep'), findsOneWidget);
    expect(find.text('Nappy'), findsOneWidget);
    expect(find.text('Pump'), findsNothing);
    await tester.tap(find.text('Feed'));
    await tester.pump();
    expect(find.text('Feed — Amelia'), findsOneWidget);
    expect(find.text('Amount eaten'), findsOneWidget);
    expect(find.textContaining('Time:'), findsOneWidget);
  });

  testWidgets('new family setup starts with two baby forms', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentFamilyIdProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add your babies'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Baby 1 name'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Baby 2 name'), findsOneWidget);
    expect(find.text('Create family'), findsOneWidget);
  });

  testWidgets('settings add-baby form captures name and birth date', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: AddBabySheet(familyId: 'family')),
        ),
      ),
    );

    expect(find.text('Add another baby'), findsOneWidget);
    expect(find.text('Baby name'), findsOneWidget);
    expect(find.textContaining('Born'), findsOneWidget);
    expect(find.text('Add baby'), findsOneWidget);
  });

  testWidgets('history merges baby subcollections without collection group', (
    tester,
  ) async {
    final now = DateTime(2026);
    final baby = Baby(
      id: 'a',
      familyId: 'f',
      name: 'Amelia',
      dateOfBirth: now,
      createdAt: now,
      createdBy: 'u',
    );
    final feed = BabyEvent(
      id: 'feed',
      familyId: 'f',
      babyId: 'a',
      type: BabyEventType.feeding,
      start: now,
      createdAt: now,
      createdBy: 'u',
      updatedAt: now,
      updatedBy: 'u',
      data: const {'amountMl': 120, 'milkType': 'formula'},
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentFamilyIdProvider.overrideWith((ref) => Stream.value('f')),
          babiesProvider('f').overrideWith((ref) => Stream.value([baby])),
          eventRepositoryProvider.overrideWithValue(_EventRepository([feed])),
        ],
        child: const MaterialApp(home: HistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('120 ml'), findsOneWidget);
    expect(find.textContaining('Amelia'), findsOneWidget);
  });

  testWidgets('statistics period can be changed', (tester) async {
    final now = DateTime.now();
    final baby = Baby(
      id: 'a',
      familyId: 'f',
      name: 'Amelia',
      dateOfBirth: now,
      createdAt: now,
      createdBy: 'u',
    );
    final growth = BabyEvent(
      id: 'growth',
      familyId: 'f',
      babyId: 'a',
      type: BabyEventType.growth,
      start: now,
      createdAt: now,
      createdBy: 'u',
      updatedAt: now,
      updatedBy: 'u',
      data: const {'weightKg': 3.4, 'heightCm': 51.0},
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentFamilyIdProvider.overrideWith((ref) => Stream.value('f')),
          babiesProvider('f').overrideWith((ref) => Stream.value([baby])),
          eventRepositoryProvider.overrideWithValue(_EventRepository([growth])),
        ],
        child: const MaterialApp(home: StatisticsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Whole family'), findsOneWidget);
    await tester.tap(find.text('Whole family'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Amelia').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Month'));
    await tester.pump();
    expect(find.text('Month'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('3.40 kg'), findsOneWidget);
    expect(find.text('51.00 cm'), findsOneWidget);
  });

  testWidgets('registration rejects a display name entered as an email', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AuthScreen())),
    );
    await tester.tap(find.text('New here? Create account'));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).at(0), 'Ryan');
    await tester.enterText(find.byType(TextFormField).at(1), 'Ryan');
    await tester.enterText(find.byType(TextFormField).at(2), 'password');
    await tester.tap(find.text('Create account'));
    await tester.pump();

    expect(
      find.text('Enter a complete email, such as ryan@example.com.'),
      findsOneWidget,
    );
  });
}

class _EventRepository implements BabyEventRepository {
  _EventRepository(this.events);

  final List<BabyEvent> events;

  @override
  Stream<List<BabyEvent>> watchEvents({
    required String familyId,
    String? babyId,
  }) => Stream.value(
    events.where((event) => event.babyId == babyId).toList(),
  );

  @override
  Future<void> createEvent(BabyEvent event) async {}

  @override
  Future<void> updateEvent(BabyEvent event) async {}

  @override
  Future<void> deleteEvent({
    required String familyId,
    required String babyId,
    required String eventId,
  }) async {}
}
