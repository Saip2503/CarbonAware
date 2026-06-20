import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/co2_calculator.dart';

class DailyLog {
  final String date; // YYYY-MM-DD
  final double transportMiles;
  final VehicleType vehicleType;
  final DietType dietType;
  final double electricityKwh;
  final double totalCO2Kg;
  final DateTime timestamp;

  DailyLog({
    required this.date,
    required this.transportMiles,
    required this.vehicleType,
    required this.dietType,
    required this.electricityKwh,
    required this.totalCO2Kg,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'transportMiles': transportMiles,
      'vehicleType': vehicleType.name,
      'dietType': dietType.toFirestoreString(),
      'electricityKwh': electricityKwh,
      'totalCO2Kg': totalCO2Kg,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory DailyLog.fromMap(Map<String, dynamic> map, String docId) {
    final vehicle = VehicleType.fromString(map['vehicleType'] as String? ?? 'car');
    final diet = DietType.fromString(map['dietType'] as String? ?? 'average');
    final miles = (map['transportMiles'] as num?)?.toDouble() ?? 0.0;
    final kwh = (map['electricityKwh'] as num?)?.toDouble() ?? 0.0;
    
    // Fallback recalculate if stored value is missing
    final defaultTotal = CO2Calculator.calculateTotal(
      miles: miles,
      vehicleType: vehicle,
      dietType: diet,
      electricityKwh: kwh,
    );

    return DailyLog(
      date: docId,
      transportMiles: miles,
      vehicleType: vehicle,
      dietType: diet,
      electricityKwh: kwh,
      totalCO2Kg: (map['totalCO2Kg'] as num?)?.toDouble() ?? defaultTotal,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  DailyLog copyWith({
    String? date,
    double? transportMiles,
    VehicleType? vehicleType,
    DietType? dietType,
    double? electricityKwh,
    double? totalCO2Kg,
    DateTime? timestamp,
  }) {
    return DailyLog(
      date: date ?? this.date,
      transportMiles: transportMiles ?? this.transportMiles,
      vehicleType: vehicleType ?? this.vehicleType,
      dietType: dietType ?? this.dietType,
      electricityKwh: electricityKwh ?? this.electricityKwh,
      totalCO2Kg: totalCO2Kg ?? this.totalCO2Kg,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
