import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/co2_calculator.dart';

class DailyLog {
  final String date; // YYYY-MM-DD
  final double transportDistance;
  final bool isKm;
  final VehicleType vehicleType;
  final DietType dietType;
  final double electricityKwh;
  final double totalCO2Kg;
  final DateTime timestamp;

  DailyLog({
    required this.date,
    required this.transportDistance,
    required this.isKm,
    required this.vehicleType,
    required this.dietType,
    required this.electricityKwh,
    required this.totalCO2Kg,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'transportDistance': transportDistance,
      'isKm': isKm,
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
    final isKm = map['isKm'] as bool? ?? false;
    
    // Migration: read transportDistance, fallback to transportMiles if missing
    final distance = (map['transportDistance'] as num?)?.toDouble() ?? 
                     (map['transportMiles'] as num?)?.toDouble() ?? 0.0;
                     
    final kwh = (map['electricityKwh'] as num?)?.toDouble() ?? 0.0;
    
    // Fallback recalculate if stored value is missing
    final defaultTotal = CO2Calculator.calculateTotal(
      distance: distance,
      vehicleType: vehicle,
      dietType: diet,
      electricityKwh: kwh,
      isKm: isKm,
    );

    return DailyLog(
      date: docId,
      transportDistance: distance,
      isKm: isKm,
      vehicleType: vehicle,
      dietType: diet,
      electricityKwh: kwh,
      totalCO2Kg: (map['totalCO2Kg'] as num?)?.toDouble() ?? defaultTotal,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  DailyLog copyWith({
    String? date,
    double? transportDistance,
    bool? isKm,
    VehicleType? vehicleType,
    DietType? dietType,
    double? electricityKwh,
    double? totalCO2Kg,
    DateTime? timestamp,
  }) {
    return DailyLog(
      date: date ?? this.date,
      transportDistance: transportDistance ?? this.transportDistance,
      isKm: isKm ?? this.isKm,
      vehicleType: vehicleType ?? this.vehicleType,
      dietType: dietType ?? this.dietType,
      electricityKwh: electricityKwh ?? this.electricityKwh,
      totalCO2Kg: totalCO2Kg ?? this.totalCO2Kg,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
