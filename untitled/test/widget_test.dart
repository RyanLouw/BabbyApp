import 'package:babby_care/features/events/presentation/record_event_sheet.dart';
import 'package:babby_care/features/home/presentation/home_screen.dart';
import 'package:babby_care/features/statistics/presentation/statistics_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dashboard shows both babies and current state', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    expect(find.text('Baby A'), findsOneWidget);
    expect(find.text('Baby B'), findsOneWidget);
    expect(find.textContaining('Sleeping'), findsOneWidget);
  });

  testWidgets('quick entry exposes common events', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: RecordEventSheet())),
    );

    expect(find.text('Feed'), findsOneWidget);
    expect(find.text('Sleep'), findsOneWidget);
    expect(find.text('Nappy'), findsOneWidget);
  });

  testWidgets('statistics period can be changed', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: StatisticsScreen()));

    expect(find.text('All babies — Today'), findsOneWidget);
    await tester.tap(find.text('7 days'));
    await tester.pump();
    expect(find.text('All babies — 7 days'), findsOneWidget);
  });
}
