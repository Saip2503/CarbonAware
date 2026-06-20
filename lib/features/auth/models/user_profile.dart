import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final DateTime creationDate;
  final double dailyGoalKgCO2;

  UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.creationDate,
    required this.dailyGoalKgCO2,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'creationDate': Timestamp.fromDate(creationDate),
      'dailyGoalKgCO2': dailyGoalKgCO2,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      creationDate: (map['creationDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dailyGoalKgCO2: (map['dailyGoalKgCO2'] as num?)?.toDouble() ?? 6.8, // 6.8 kg CO2e is a standard sustainable daily budget
    );
  }

  UserProfile copyWith({
    String? uid,
    String? displayName,
    String? email,
    DateTime? creationDate,
    double? dailyGoalKgCO2,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      creationDate: creationDate ?? this.creationDate,
      dailyGoalKgCO2: dailyGoalKgCO2 ?? this.dailyGoalKgCO2,
    );
  }
}
