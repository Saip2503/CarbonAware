import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_profile.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user uid
  String? get currentUid => _auth.currentUser?.uid;

  // Stream of current user profile
  Stream<UserProfile?> userProfileStream(String uid) {
    if (uid.isEmpty) return Stream.value(null);
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists || snapshot.data() == null) {
            return null;
          }
          return UserProfile.fromMap(snapshot.data()!);
        });
  }

  // Sign In with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Register with email, password, and displayName
  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user != null) {
      await user.updateDisplayName(displayName);
      // Create user profile in Firestore
      final userProfile = UserProfile(
        uid: user.uid,
        displayName: displayName,
        email: email,
        creationDate: DateTime.now(),
        dailyGoalKgCO2: 6.8, // 6.8 kg CO2e is default
        isOnboarded: false, // Onboarding required
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userProfile.toMap());
    }

    return credential;
  }

  // Sign In with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      // Create Firestore profile if new user
      if (user != null && userCredential.additionalUserInfo?.isNewUser == true) {
        final userProfile = UserProfile(
          uid: user.uid,
          displayName: user.displayName ?? 'EcoWarrior',
          email: user.email ?? '',
          creationDate: DateTime.now(),
          dailyGoalKgCO2: 6.8,
          isOnboarded: false, // Onboarding required
        );
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userProfile.toMap());
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // Update user goal and onboard status
  Future<void> updateUserGoalAndOnboardStatus(String uid, double dailyGoal) async {
    if (uid.isEmpty) return;
    await _firestore.collection('users').doc(uid).update({
      'dailyGoalKgCO2': dailyGoal,
      'isOnboarded': true,
    });
  }
}
