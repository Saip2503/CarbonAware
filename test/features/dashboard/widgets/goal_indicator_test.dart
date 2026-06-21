import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:carbon_aware/features/dashboard/presentation/widgets/goal_indicator.dart';
import 'package:carbon_aware/core/constants/app_colors.dart';

void main() {
  Widget buildTestWidget(double today, double goal) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: GoalIndicator(
            todayValue: today,
            dailyGoal: goal,
          ),
        ),
      ),
    );
  }

  group('GoalIndicator Widget Tests', () {
    testWidgets('shows On Track status when ratio is < 0.8', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(4.0, 10.0)); // 0.4 ratio
      await tester.pumpAndSettle();

      expect(find.text('On Track'), findsOneWidget);
      expect(find.text('4.0'), findsOneWidget);
      expect(find.text('/ 10.0 kg'), findsOneWidget);

      final containerFinder = find.ancestor(
        of: find.text('On Track'),
        matching: find.byType(Container),
      );
      final container = tester.widget<Container>(containerFinder.first);
      final boxDecoration = container.decoration as BoxDecoration;
      final border = boxDecoration.border as Border;
      // Border color should have success color opacity
      expect(border.top.color.value, AppColors.success.withOpacity(0.3).value);
    });

    testWidgets('shows Approaching Limit status when ratio is >= 0.8 and <= 1.0', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(8.5, 10.0)); // 0.85 ratio
      await tester.pumpAndSettle();

      expect(find.text('Approaching Limit'), findsOneWidget);
      expect(find.text('8.5'), findsOneWidget);

      final containerFinder = find.ancestor(
        of: find.text('Approaching Limit'),
        matching: find.byType(Container),
      );
      final container = tester.widget<Container>(containerFinder.first);
      final boxDecoration = container.decoration as BoxDecoration;
      final border = boxDecoration.border as Border;
      expect(border.top.color.value, AppColors.warning.withOpacity(0.3).value);
    });

    testWidgets('shows Exceeded Goal status when ratio is > 1.0', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(12.0, 10.0)); // 1.2 ratio
      await tester.pumpAndSettle();

      expect(find.text('Exceeded Goal'), findsOneWidget);
      expect(find.text('12.0'), findsOneWidget);

      final containerFinder = find.ancestor(
        of: find.text('Exceeded Goal'),
        matching: find.byType(Container),
      );
      final container = tester.widget<Container>(containerFinder.first);
      final boxDecoration = container.decoration as BoxDecoration;
      final border = boxDecoration.border as Border;
      expect(border.top.color.value, AppColors.error.withOpacity(0.3).value);
    });
  });
}
