import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:carbon_aware/features/auth/data/auth_repository.dart';
import 'package:carbon_aware/features/auth/domain/user_profile.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockGoogleSignIn extends Mock implements GoogleSignIn {}
class MockUserCredential extends Mock implements UserCredential {}
class MockUser extends Mock implements User {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}
class MockGoogleSignInAuthentication extends Mock implements GoogleSignInAuthentication {}
class MockAuthCredential extends Mock implements AuthCredential {}
class MockAdditionalUserInfo extends Mock implements AdditionalUserInfo {}

class FakeAuthCredential extends Fake implements AuthCredential {}

void main() {
  late MockFirebaseAuth mockAuth;
  late MockFirebaseFirestore mockFirestore;
  late MockGoogleSignIn mockGoogleSignIn;
  late AuthRepository authRepository;

  setUpAll(() {
    registerFallbackValue(FakeAuthCredential());
  });

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    mockGoogleSignIn = MockGoogleSignIn();
    authRepository = AuthRepository(
      auth: mockAuth,
      firestore: mockFirestore,
      googleSignIn: mockGoogleSignIn,
    );
  });

  group('AuthRepository', () {
    test('authStateChanges returns stream of users', () {
      final mockUser = MockUser();
      when(() => mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(mockUser));

      expect(authRepository.authStateChanges, emits(mockUser));
      verify(() => mockAuth.authStateChanges()).called(1);
    });

    test('currentUid returns correct uid', () {
      final mockUser = MockUser();
      when(() => mockUser.uid).thenReturn('test_uid');
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      expect(authRepository.currentUid, 'test_uid');
    });

    test('currentUid returns null when user is null', () {
      when(() => mockAuth.currentUser).thenReturn(null);

      expect(authRepository.currentUid, null);
    });

    test('userProfileStream returns profile when found', () async {
      final mockDocRef = MockDocumentReference();
      final mockDocSnapshot = MockDocumentSnapshot();
      final mockColRef = MockCollectionReference();

      when(() => mockFirestore.collection('users')).thenReturn(mockColRef);
      when(() => mockColRef.doc('test_uid')).thenReturn(mockDocRef);
      when(() => mockDocRef.snapshots()).thenAnswer((_) => Stream.value(mockDocSnapshot));
      when(() => mockDocSnapshot.exists).thenReturn(true);
      when(() => mockDocSnapshot.data()).thenReturn({
        'uid': 'test_uid',
        'displayName': 'Test User',
        'email': 'test@example.com',
        'creationDate': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'dailyGoalKgCO2': 6.8,
        'isOnboarded': true,
      });

      final result = await authRepository.userProfileStream('test_uid').first;
      expect(result, isNotNull);
      expect(result!.uid, 'test_uid');
      expect(result.displayName, 'Test User');
    });

    test('userProfileStream returns null when doc does not exist', () async {
      final mockDocRef = MockDocumentReference();
      final mockDocSnapshot = MockDocumentSnapshot();
      final mockColRef = MockCollectionReference();

      when(() => mockFirestore.collection('users')).thenReturn(mockColRef);
      when(() => mockColRef.doc('test_uid')).thenReturn(mockDocRef);
      when(() => mockDocRef.snapshots()).thenAnswer((_) => Stream.value(mockDocSnapshot));
      when(() => mockDocSnapshot.exists).thenReturn(false);

      final result = await authRepository.userProfileStream('test_uid').first;
      expect(result, isNull);
    });

    test('signInWithEmailAndPassword calls firebase auth', () async {
      final mockUserCredential = MockUserCredential();
      when(() => mockAuth.signInWithEmailAndPassword(
            email: 'test@example.com',
            password: 'password123',
          )).thenAnswer((_) => Future.value(mockUserCredential));

      final result = await authRepository.signInWithEmailAndPassword(
        'test@example.com',
        'password123',
      );

      expect(result, mockUserCredential);
      verify(() => mockAuth.signInWithEmailAndPassword(
            email: 'test@example.com',
            password: 'password123',
          )).called(1);
    });

    test('registerWithEmailAndPassword creates user and sets Firestore profile', () async {
      final mockUserCredential = MockUserCredential();
      final mockUser = MockUser();
      final mockColRef = MockCollectionReference();
      final mockDocRef = MockDocumentReference();

      when(() => mockUser.uid).thenReturn('new_uid');
      when(() => mockUser.updateDisplayName(any())).thenAnswer((_) => Future.value());
      when(() => mockUserCredential.user).thenReturn(mockUser);

      when(() => mockAuth.createUserWithEmailAndPassword(
            email: 'new@example.com',
            password: 'password123',
          )).thenAnswer((_) => Future.value(mockUserCredential));

      when(() => mockFirestore.collection('users')).thenReturn(mockColRef);
      when(() => mockColRef.doc('new_uid')).thenReturn(mockDocRef);
      when(() => mockDocRef.set(any())).thenAnswer((_) => Future.value());

      final result = await authRepository.registerWithEmailAndPassword(
        'new@example.com',
        'password123',
        'Eco Champ',
      );

      expect(result, mockUserCredential);
      verify(() => mockAuth.createUserWithEmailAndPassword(
            email: 'new@example.com',
            password: 'password123',
          )).called(1);
      verify(() => mockUser.updateDisplayName('Eco Champ')).called(1);
      verify(() => mockDocRef.set(any())).called(1);
    });

    test('signInWithGoogle signs in and sets profile if new user', () async {
      final mockGoogleUser = MockGoogleSignInAccount();
      final mockGoogleAuth = MockGoogleSignInAuthentication();
      final mockUserCredential = MockUserCredential();
      final mockUser = MockUser();
      final mockAdditionalUserInfo = MockAdditionalUserInfo();
      final mockColRef = MockCollectionReference();
      final mockDocRef = MockDocumentReference();

      when(() => mockGoogleSignIn.signIn()).thenAnswer((_) => Future.value(mockGoogleUser));
      when(() => mockGoogleUser.authentication).thenAnswer((_) => Future.value(mockGoogleAuth));
      when(() => mockGoogleAuth.accessToken).thenReturn('access_token');
      when(() => mockGoogleAuth.idToken).thenReturn('id_token');

      when(() => mockUser.uid).thenReturn('google_uid');
      when(() => mockUser.displayName).thenReturn('Google Eco');
      when(() => mockUser.email).thenReturn('google@example.com');
      when(() => mockUserCredential.user).thenReturn(mockUser);
      when(() => mockUserCredential.additionalUserInfo).thenReturn(mockAdditionalUserInfo);
      when(() => mockAdditionalUserInfo.isNewUser).thenReturn(true);

      when(() => mockAuth.signInWithCredential(any())).thenAnswer((_) => Future.value(mockUserCredential));

      when(() => mockFirestore.collection('users')).thenReturn(mockColRef);
      when(() => mockColRef.doc('google_uid')).thenReturn(mockDocRef);
      when(() => mockDocRef.set(any())).thenAnswer((_) => Future.value());

      final result = await authRepository.signInWithGoogle();

      expect(result, mockUserCredential);
      verify(() => mockGoogleSignIn.signIn()).called(1);
      verify(() => mockAuth.signInWithCredential(any())).called(1);
      verify(() => mockDocRef.set(any())).called(1);
    });

    test('signOut calls FirebaseAuth and GoogleSignIn signOut', () async {
      when(() => mockAuth.signOut()).thenAnswer((_) => Future.value());
      when(() => mockGoogleSignIn.signOut()).thenAnswer((_) => Future.value(null));

      await authRepository.signOut();

      verify(() => mockAuth.signOut()).called(1);
      verify(() => mockGoogleSignIn.signOut()).called(1);
    });

    test('updateUserGoalAndOnboardStatus updates Firestore', () async {
      final mockColRef = MockCollectionReference();
      final mockDocRef = MockDocumentReference();

      when(() => mockFirestore.collection('users')).thenReturn(mockColRef);
      when(() => mockColRef.doc('test_uid')).thenReturn(mockDocRef);
      when(() => mockDocRef.update(any())).thenAnswer((_) => Future.value());

      await authRepository.updateUserGoalAndOnboardStatus('test_uid', 5.5);

      verify(() => mockDocRef.update({
        'dailyGoalKgCO2': 5.5,
        'isOnboarded': true,
      })).called(1);
    });
  });
}
