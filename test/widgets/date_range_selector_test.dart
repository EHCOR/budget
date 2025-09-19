import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budget_tracker/widgets/date_range_selector.dart';
import 'package:budget_tracker/providers/transaction_provider.dart';
import 'package:budget_tracker/models/transaction.dart';

void main() {
  group('DateRangeSelector Widget Tests', () {
    late TransactionProvider provider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      provider = TransactionProvider();
      await provider.initialize();
    });

    Widget createTestWidget({bool showTrendsOptions = false}) {
      return MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<TransactionProvider>.value(
            value: provider,
            child: DateRangeSelector(showTrendsOptions: showTrendsOptions),
          ),
        ),
      );
    }

    testWidgets('displays current date range', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Should display the current date range
      expect(find.byType(DateRangeSelector), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);

      // Should show formatted date range
      expect(find.textContaining(' - '), findsOneWidget);
    });

    testWidgets('shows quick date range options', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Should show quick option buttons
      expect(find.text('Last 7 Days'), findsOneWidget);
      expect(find.text('Last 30 Days'), findsOneWidget);
      expect(find.text('This Month'), findsOneWidget);
      expect(find.text('Last Month'), findsOneWidget);
      expect(find.text('Last 3 Months'), findsOneWidget);
      expect(find.text('All Time'), findsOneWidget);
    });

    testWidgets('quick options update date range', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final initialStartDate = provider.startDate;
      final initialEndDate = provider.endDate;

      // Tap on "Last 7 Days"
      await tester.tap(find.text('Last 7 Days'));
      await tester.pumpAndSettle();

      // Date range should have changed
      expect(provider.startDate, isNot(equals(initialStartDate)));
      expect(provider.endDate, equals(initialEndDate)); // End date should remain today

      // Start date should be approximately 7 days ago
      final expectedStartDate = DateTime.now().subtract(const Duration(days: 7));
      expect(provider.startDate.difference(expectedStartDate).inDays.abs(), lessThan(1));
    });

    testWidgets('Last 30 Days option works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Last 30 Days'));
      await tester.pumpAndSettle();

      final expectedStartDate = DateTime.now().subtract(const Duration(days: 30));
      expect(provider.startDate.difference(expectedStartDate).inDays.abs(), lessThan(1));
    });

    testWidgets('Last 3 Months option works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Last 3 Months'));
      await tester.pumpAndSettle();

      // Should set start date to 3 months ago
      final now = DateTime.now();
      final expectedStartDate = DateTime(now.year, now.month - 3, now.day);
      expect(provider.startDate.year, expectedStartDate.year);
      expect(provider.startDate.month, expectedStartDate.month);
    });

    testWidgets('This Month option works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('This Month'));
      await tester.pumpAndSettle();

      // Should set start date to beginning of current month
      final now = DateTime.now();
      final expectedStartDate = DateTime(now.year, now.month, 1);
      expect(provider.startDate.year, expectedStartDate.year);
      expect(provider.startDate.month, expectedStartDate.month);
      expect(provider.startDate.day, expectedStartDate.day);
    });

    testWidgets('Last Month option works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Last Month'));
      await tester.pumpAndSettle();

      // Should set start date to beginning of last month
      final now = DateTime.now();
      final expectedStartDate = DateTime(now.year, now.month - 1, 1);
      expect(provider.startDate.year, expectedStartDate.year);
      expect(provider.startDate.month, expectedStartDate.month);
      expect(provider.startDate.day, expectedStartDate.day);
    });

    testWidgets('All Time option works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // First add a transaction so All Time has data to work with
      await provider.addTransaction(Transaction(
        date: DateTime(2020, 1, 1),
        description: 'Old transaction',
        amount: 100.0,
      ));

      await tester.tap(find.text('All Time'));
      await tester.pumpAndSettle();

      // Should set start date to earliest transaction date
      expect(provider.startDate.year, 2020);
      expect(provider.startDate.month, 1);
      expect(provider.startDate.day, 1);
    });

    testWidgets('shows trends options when enabled', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(showTrendsOptions: true));

      // Should show additional trend-specific options
      expect(find.text('Last 6 Months'), findsOneWidget);
      expect(find.text('Last 1 Year'), findsOneWidget);
    });

    testWidgets('hides trends options when disabled', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(showTrendsOptions: false));

      // Should not show trend-specific options
      expect(find.text('Last 6 Months'), findsNothing);
      expect(find.text('Last 1 Year'), findsNothing);
    });

    testWidgets('trends options work correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(showTrendsOptions: true));

      // Test Last 6 Months
      await tester.tap(find.text('Last 6 Months'));
      await tester.pumpAndSettle();

      final now = DateTime.now();
      final expectedStartDate = DateTime(now.year, now.month - 6, now.day);
      expect(provider.startDate.year, expectedStartDate.year);
      expect(provider.startDate.month, expectedStartDate.month);

      // Test Last 1 Year
      await tester.tap(find.text('Last 1 Year'));
      await tester.pumpAndSettle();

      final expectedStartDate1Year = DateTime(now.year - 1, now.month, 1);
      expect(provider.startDate.year, expectedStartDate1Year.year);
      expect(provider.startDate.month, expectedStartDate1Year.month);
    });

    testWidgets('custom date picker button works', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Should have a custom date picker button
      expect(find.text('Custom'), findsOneWidget);

      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();

      // Should show custom date range picker dialog
      expect(find.text('Select Date Range'), findsOneWidget);
    });

    testWidgets('is horizontally scrollable', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(showTrendsOptions: true));

      // Should have a horizontal scroll view for the buttons
      expect(find.byType(SingleChildScrollView), findsWidgets);

      final scrollView = find.byType(SingleChildScrollView).first;
      final widget = tester.widget<SingleChildScrollView>(scrollView);
      expect(widget.scrollDirection, Axis.horizontal);
    });

    testWidgets('buttons have proper styling', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find one of the buttons
      final buttonFinder = find.text('Last 7 Days');
      expect(buttonFinder, findsOneWidget);

      // Should be wrapped in an InkWell (based on the actual implementation)
      final buttonWidget = find.ancestor(
        of: buttonFinder,
        matching: find.byType(InkWell),
      );
      expect(buttonWidget, findsOneWidget);
    });

    testWidgets('updates display when provider changes', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Get initial date range text
      final initialText = find.textContaining(' - ');
      expect(initialText, findsOneWidget);

      // Manually change the provider's date range
      provider.setDateRange(
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 31),
      );
      await tester.pumpAndSettle();

      // Should show updated date range
      expect(find.text('Jan 1 - Jan 31'), findsOneWidget);
    });

    testWidgets('handles edge cases gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Test with dates at year boundaries
      provider.setDateRange(
        DateTime(2023, 12, 31),
        DateTime(2024, 1, 1),
      );
      await tester.pumpAndSettle();

      // Should handle year transition properly
      expect(find.textContaining('Dec 31 - Jan 1'), findsOneWidget);
    });

    testWidgets('custom date picker sets correct range', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();

      // Should show custom date range picker
      expect(find.text('Select Date Range'), findsOneWidget);

      // Test canceling the dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.text('Select Date Range'), findsNothing);
    });
  });
}