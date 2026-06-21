import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:carbon_aware/features/dashboard/views/dashboard_screen.dart';
import 'package:carbon_aware/features/auth/providers/auth_providers.dart';
import 'package:carbon_aware/features/auth/models/user_profile.dart';
import 'package:carbon_aware/features/auth/data/auth_repository.dart';
import 'package:carbon_aware/features/logging/providers/log_providers.dart';
import 'package:carbon_aware/features/logging/models/daily_log.dart';
import 'package:carbon_aware/features/insights/providers/insights_provider.dart';
import 'package:carbon_aware/features/insights/models/insight.dart';
import 'package:carbon_aware/core/utils/co2_calculator.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    when(() => mockAuthRepository.signOut()).thenAnswer((_) => Future.value());
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.implicitView!.physicalSize = const Size(1200, 900);
    binding.platformDispatcher.implicitView!.devicePixelRatio = 1.0;
  });

  Widget createDashboardScreenRouter({
    required UserProfile profile,
    required List<DailyLog> logs,
    required Insight insight,
  }) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/log',
          builder: (context, state) => const Scaffold(
            body: Text('Quick Log Screen'),
          ),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const Scaffold(
            body: Text('Login Screen'),
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
        userProfileProvider.overrideWithValue(AsyncValue.data(profile)),
        recentLogsStreamProvider.overrideWithValue(AsyncValue.data(logs)),
        aiInsightProvider.overrideWithValue(AsyncValue.data(insight)),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('DashboardScreen Widget Tests', () {
    final testProfile = UserProfile(
      uid: 'test_uid',
      displayName: 'Eco Warrior',
      email: 'eco@example.com',
      creationDate: DateTime.now(),
      dailyGoalKgCO2: 6.8,
    );

    final testLogs = [
      DailyLog(
        date: DateTime.now().toIso8601String().substring(0, 10),
        transportMiles: 10.0,
        vehicleType: VehicleType.car,
        dietType: DietType.average,
        electricityKwh: 5.0,
        totalCO2Kg: 8.0,
        timestamp: DateTime.now(),
      ),
    ];

    final testInsight = Insight(
      title: 'Unplug Standby Devices',
      description: 'Turn off power strips tonight to reduce idle energy consumption.',
      category: 'energy',
      potentialSavingsKg: 1.2,
      priority: InsightPriority.medium,
    );

    testWidgets('renders greeting, goal indicator, insight card, and breakdown charts', (WidgetTester tester) async {
      await tester.pumpWidget(createDashboardScreenRouter(
        profile: testProfile,
        logs: testLogs,
        insight: testInsight,
      ));
      await tester.pumpAndSettle();

      // Check header greeting
      expect(find.text('Hi, Eco'), findsOneWidget);
      expect(find.text('CarbonAware'), findsOneWidget);

      // Check Goal indicator is rendering today value vs goal
      expect(find.text('8.0'), findsOneWidget);
      expect(find.text('/ 6.8 kg'), findsOneWidget);
      expect(find.text('Exceeded Goal'), findsOneWidget);

      // Check AI Insights card is rendering
      expect(find.text('Unplug Standby Devices'), findsOneWidget);
      expect(find.text('Turn off power strips tonight to reduce idle energy consumption.'), findsOneWidget);

      // Check weekly chart header
      expect(find.text('Weekly Emissions'), findsOneWidget);

      // Check emission breakdown header
      expect(find.text('Emission Sources'), findsOneWidget);
    });

    testWidgets('navigates to Quick Log screen when Edit Log button is pressed', (WidgetTester tester) async {
      await tester.pumpWidget(createDashboardScreenRouter(
        profile: testProfile,
        logs: testLogs,
        insight: testInsight,
      ));
      await tester.pumpAndSettle();

      final editLogButton = find.byIcon(Icons.add_circle_outline_rounded);
      expect(editLogButton, findsOneWidget);

      await tester.tap(editLogButton);
      await tester.pumpAndSettle();

      expect(find.text('Quick Log Screen'), findsOneWidget);
    });

    testWidgets('prompts confirmation dialog and logouts when logout button is pressed', (WidgetTester tester) async {
      await tester.pumpWidget(createDashboardScreenRouter(
        profile: testProfile,
        logs: testLogs,
        insight: testInsight,
      ));
      await tester.pumpAndSettle();

      final logoutButton = find.byIcon(Icons.logout_rounded);
      expect(logoutButton, findsOneWidget);

      await tester.tap(logoutButton);
      await tester.pumpAndSettle();

      // Check if alert dialog appears
      expect(find.text('Sign Out'), findsNWidgets(2)); // Title and Button
      expect(find.text('Are you sure you want to sign out of CarbonAware?'), findsOneWidget);

      // Tap confirm button
      await tester.tap(find.widgetWithText(TextButton, 'Sign Out'));
      await tester.pumpAndSettle();

      verify(() => mockAuthRepository.signOut()).called(1);
      expect(find.text('Login Screen'), findsOneWidget);
    });
  });
}
