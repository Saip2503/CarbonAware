import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carbon_aware/features/logging/presentation/views/quick_log_screen.dart';
import 'package:carbon_aware/features/logging/domain/daily_log.dart';
import 'package:carbon_aware/features/logging/presentation/providers/log_providers.dart';
import 'package:carbon_aware/features/logging/data/log_repository.dart';
import 'package:carbon_aware/features/auth/presentation/providers/auth_providers.dart';
import 'package:carbon_aware/core/utils/co2_calculator.dart';

class MockLogRepository extends Mock implements LogRepository {}
class MockUser extends Mock implements User {}

void main() {
  late MockLogRepository mockLogRepository;
  late MockUser mockUser;

  setUp(() {
    mockLogRepository = MockLogRepository();
    mockUser = MockUser();

    when(() => mockUser.uid).thenReturn('test_uid');
    
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.implicitView!.physicalSize = const Size(1200, 2000);
    binding.platformDispatcher.implicitView!.devicePixelRatio = 1.0;
    
    // Register fallbacks
    registerFallbackValue(
      DailyLog(
        date: '2026-06-22',
        transportDistance: 0.0,
        isKm: false,
        vehicleType: VehicleType.car,
        dietType: DietType.average,
        electricityKwh: 0.0,
        totalCO2Kg: 0.0,
        timestamp: DateTime.now(),
      ),
    );
  });

  Widget createQuickLogScreenRouter({DailyLog? initialLog}) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const QuickLogScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const Scaffold(
            body: Text('Dashboard Screen'),
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authStateProvider.overrideWithValue(AsyncValue.data(mockUser)),
        logRepositoryProvider.overrideWithValue(mockLogRepository),
        todaysLogProvider.overrideWith((ref) async => initialLog),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('QuickLogScreen Widget Tests', () {
    testWidgets('renders all log input sections', (WidgetTester tester) async {
      await tester.pumpWidget(createQuickLogScreenRouter());
      await tester.pumpAndSettle();

      expect(find.text('Daily Quick-Log'), findsOneWidget);
      expect(find.text('TODAY\'S FOOTPRINT ESTIMATE'), findsOneWidget);
      expect(find.text('Transportation'), findsOneWidget);
      expect(find.text('Vehicle Type:'), findsOneWidget);
      expect(find.text('Dietary Footprint'), findsOneWidget);
      expect(find.text('Select your diet type today:'), findsOneWidget);
      expect(find.text('Home Energy'), findsOneWidget);
      expect(find.text('Save Daily Log'), findsOneWidget);
    });

    testWidgets('populates fields if today\'s log exists', (WidgetTester tester) async {
      final existingLog = DailyLog(
        date: '2026-06-22',
        transportDistance: 25.0,
        isKm: false,
        vehicleType: VehicleType.bus,
        dietType: DietType.vegetarian,
        electricityKwh: 12.0,
        totalCO2Kg: 10.0,
        timestamp: DateTime(2026, 6, 22),
      );

      await tester.pumpWidget(createQuickLogScreenRouter(initialLog: existingLog));
      await tester.pumpAndSettle();

      expect(find.text('Daily Commute: 25.0 miles'), findsOneWidget);
      expect(find.text('Electricity Consumption: 12.0 kWh'), findsOneWidget);
      expect(find.text('Delete Today\'s Log'), findsOneWidget);
    });

    testWidgets('updates transport slider and total estimate', (WidgetTester tester) async {
      await tester.pumpWidget(createQuickLogScreenRouter());
      await tester.pumpAndSettle();

      // Locate transport slider
      final Finder sliderFinder = find.byType(Slider).first;
      expect(sliderFinder, findsOneWidget);

      // Drag slider
      await tester.drag(sliderFinder, const Offset(100.0, 0.0));
      await tester.pumpAndSettle();

      expect(find.text('Daily Commute: 0.0 miles'), findsNothing);
    });

    testWidgets('taps diet selection and updates state', (WidgetTester tester) async {
      await tester.pumpWidget(createQuickLogScreenRouter());
      await tester.pumpAndSettle();

      // Tap vegetarian diet
      await tester.tap(find.text('Vegetarian'));
      await tester.pumpAndSettle();

      // The estimated CO2 should adjust to Vegetarian diet footprint
      expect(find.text('Vegan'), findsOneWidget);
    });

    testWidgets('saves daily log successfully and navigates to dashboard', (WidgetTester tester) async {
      when(() => mockLogRepository.saveDailyLog(any(), any()))
          .thenAnswer((_) => Future.value());

      await tester.pumpWidget(createQuickLogScreenRouter());
      await tester.pumpAndSettle();

      // Tap Save button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save Daily Log'));
      await tester.pump();
      await tester.pumpAndSettle();

      verify(() => mockLogRepository.saveDailyLog('test_uid', any())).called(1);
      expect(find.text('Dashboard Screen'), findsOneWidget);
    });

    testWidgets('deletes daily log successfully and navigates to dashboard', (WidgetTester tester) async {
      final existingLog = DailyLog(
        date: '2026-06-22',
        transportDistance: 5.0,
        isKm: false,
        vehicleType: VehicleType.car,
        dietType: DietType.average,
        electricityKwh: 2.0,
        totalCO2Kg: 5.0,
        timestamp: DateTime.now(),
      );

      when(() => mockLogRepository.deleteDailyLog('test_uid', any()))
          .thenAnswer((_) => Future.value());

      await tester.pumpWidget(createQuickLogScreenRouter(initialLog: existingLog));
      await tester.pumpAndSettle();

      // Tap Delete button
      await tester.tap(find.widgetWithText(OutlinedButton, 'Delete Today\'s Log'));
      await tester.pump();
      await tester.pumpAndSettle();

      verify(() => mockLogRepository.deleteDailyLog('test_uid', any())).called(1);
      expect(find.text('Dashboard Screen'), findsOneWidget);
    });
  });
}
