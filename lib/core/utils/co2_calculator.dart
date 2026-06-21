import '../constants/emission_factors.dart';

enum VehicleType {
  car,
  bus,
  electric,
  bike,
  walk;

  String get displayName {
    switch (this) {
      case VehicleType.car:
        return 'Gasoline Car';
      case VehicleType.bus:
        return 'Public Bus';
      case VehicleType.electric:
        return 'Electric Car';
      case VehicleType.bike:
        return 'Bicycle';
      case VehicleType.walk:
        return 'Walking';
    }
  }

  static VehicleType fromString(String value) {
    return VehicleType.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => VehicleType.car,
    );
  }
}

enum DietType {
  meatHeavy,
  average,
  vegetarian,
  vegan;

  String get displayName {
    switch (this) {
      case DietType.meatHeavy:
        return 'Meat Heavy';
      case DietType.average:
        return 'Average/Mixed';
      case DietType.vegetarian:
        return 'Vegetarian';
      case DietType.vegan:
        return 'Vegan';
    }
  }

  static DietType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'meat_heavy':
      case 'meatheavy':
        return DietType.meatHeavy;
      case 'average':
        return DietType.average;
      case 'vegetarian':
        return DietType.vegetarian;
      case 'vegan':
        return DietType.vegan;
      default:
        return DietType.average;
    }
  }

  String toFirestoreString() {
    switch (this) {
      case DietType.meatHeavy:
        return 'meat_heavy';
      case DietType.average:
        return 'average';
      case DietType.vegetarian:
        return 'vegetarian';
      case DietType.vegan:
        return 'vegan';
    }
  }
}

class CO2Calculator {
  static double calculateTransport(double distance, VehicleType type, {bool isKm = false}) {
    if (distance < 0) return 0.0;
    final miles = isKm ? distance * 0.621371 : distance;
    switch (type) {
      case VehicleType.car:
        return miles * kCarEmission;
      case VehicleType.bus:
        return miles * kBusEmission;
      case VehicleType.electric:
        return miles * kElectricCarEmission;
      case VehicleType.bike:
        return miles * kBikeEmission;
      case VehicleType.walk:
        return miles * kWalkEmission;
    }
  }

  static double calculateDiet(DietType type) {
    switch (type) {
      case DietType.meatHeavy:
        return kMeatHeavyDiet;
      case DietType.average:
        return kAverageDiet;
      case DietType.vegetarian:
        return kVegetarianDiet;
      case DietType.vegan:
        return kVeganDiet;
    }
  }

  static double calculateEnergy(double kwh) {
    if (kwh < 0) return 0.0;
    return kwh * kElectricityEmission;
  }

  static double calculateTotal({
    required double distance,
    required VehicleType vehicleType,
    required DietType dietType,
    required double electricityKwh,
    bool isKm = false,
  }) {
    final transport = calculateTransport(distance, vehicleType, isKm: isKm);
    final diet = calculateDiet(dietType);
    final energy = calculateEnergy(electricityKwh);
    return transport + diet + energy;
  }
}
