import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carbon_aware/features/auth/views/login_screen.dart';
import 'package:carbon_aware/features/auth/providers/auth_providers.dart';
import 'package:carbon_aware/features/auth/data/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockUserCredential extends Mock implements UserCredential {}

void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.implicitView!.physicalSize = const Size(1200, 900);
    binding.platformDispatcher.implicitView!.devicePixelRatio = 1.0;
  });

  Widget createLoginScreenRouter() {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const Scaffold(
            body: Text('Dashboard Screen'),
          ),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const Scaffold(
            body: Text('Register Screen'),
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('LoginScreen Widget Tests', () {
    testWidgets('renders all widgets correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreenRouter());
      await tester.pumpAndSettle();

      expect(find.text('CarbonAware'), findsOneWidget);
      expect(find.text('Track, understand, and reduce your carbon footprint.'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('or sign in with email'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);
      expect(find.text("Don't have an account? "), findsOneWidget);
      expect(find.text('Register'), findsOneWidget);
    });

    testWidgets('shows validation errors when fields are empty and Sign In is pressed', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreenRouter());
      await tester.pumpAndSettle();

      // Tap Sign In button
      final signInButton = find.widgetWithText(ElevatedButton, 'Sign In');
      await tester.tap(signInButton);
      await tester.pump();

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('shows invalid email validation error', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreenRouter());
      await tester.pumpAndSettle();

      // Fill in invalid email
      await tester.enterText(find.byType(TextFormField).first, 'invalid-email');
      await tester.enterText(find.byType(TextFormField).last, 'password123');

      // Tap Sign In button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pump();

      expect(find.text('Please enter a valid email'), findsOneWidget);
      expect(find.text('Please enter your email'), findsNothing);
    });

    testWidgets('shows short password validation error', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreenRouter());
      await tester.pumpAndSettle();

      // Fill in email and short password
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, '123');

      // Tap Sign In button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pump();

      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('triggers email signIn and navigates on success', (WidgetTester tester) async {
      final mockCredential = MockUserCredential();
      when(() => mockAuthRepository.signInWithEmailAndPassword(
            'test@example.com',
            'password123',
          )).thenAnswer((_) => Future.value(mockCredential));

      await tester.pumpWidget(createLoginScreenRouter());
      await tester.pumpAndSettle();

      // Enter valid fields
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, 'password123');

      // Tap Sign In
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pump(); // Start loading
      
      // Let authentication future complete and navigations run
      await tester.pumpAndSettle();

      verify(() => mockAuthRepository.signInWithEmailAndPassword(
            'test@example.com',
            'password123',
          )).called(1);

      // Verify redirection to Dashboard
      expect(find.text('Dashboard Screen'), findsOneWidget);
    });

    testWidgets('triggers google signIn and navigates on success', (WidgetTester tester) async {
      final mockCredential = MockUserCredential();
      when(() => mockAuthRepository.signInWithGoogle())
          .thenAnswer((_) => Future.value(mockCredential));

      await tester.pumpWidget(createLoginScreenRouter());
      await tester.pumpAndSettle();

      // Tap Continue with Google
      await tester.tap(find.text('Continue with Google'));
      await tester.pump();
      await tester.pumpAndSettle();

      verify(() => mockAuthRepository.signInWithGoogle()).called(1);
      expect(find.text('Dashboard Screen'), findsOneWidget);
    });

    testWidgets('displays error message on email signIn failure', (WidgetTester tester) async {
      when(() => mockAuthRepository.signInWithEmailAndPassword(
            'test@example.com',
            'password123',
          )).thenThrow(FirebaseAuthException(code: 'user-not-found', message: 'User not found.'));

      await tester.pumpWidget(createLoginScreenRouter());
      await tester.pumpAndSettle();

      // Enter fields
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, 'password123');

      // Tap Sign In
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('User not found.'), findsOneWidget);
    });

    testWidgets('navigates to register screen on clicking Register text button', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreenRouter());
      await tester.pumpAndSettle();

      // Click Register
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      expect(find.text('Register Screen'), findsOneWidget);
    });
  });
}
