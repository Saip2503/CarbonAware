import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      // Create user profile in Firestore
      final userProfile = UserProfile(
        uid: user.uid,
        displayName: displayName,
        email: email,
        creationDate: DateTime.now(),
        dailyGoalKgCO2: 6.8, // 6.8 kg CO2e is default
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userProfile.toMap());
    }

    return credential;
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
