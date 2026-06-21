import 'package:flutter_test/flutter_test.dart';
import 'package:carbon_aware/core/utils/co2_calculator.dart';

void main() {
  group('CO2Calculator Transport Tests', () {
    test('Zero miles transport should be zero emissions', () {
      expect(CO2Calculator.calculateTransport(0.0, VehicleType.car), 0.0);
      expect(CO2Calculator.calculateTransport(0.0, VehicleType.bus), 0.0);
      expect(CO2Calculator.calculateTransport(0.0, VehicleType.bike), 0.0);
      expect(CO2Calculator.calculateTransport(0.0, VehicleType.walk), 0.0);
    });

    test('Negative miles should return zero emissions', () {
      expect(CO2Calculator.calculateTransport(-5.0, VehicleType.car), 0.0);
    });

    test('Active transit (bike, walk) should have zero emissions', () {
      expect(CO2Calculator.calculateTransport(10.0, VehicleType.bike), 0.0);
      expect(CO2Calculator.calculateTransport(15.5, VehicleType.walk), 0.0);
    });

    test('Gasoline car emissions match kCarEmission', () {
      expect(CO2Calculator.calculateTransport(10.0, VehicleType.car), closeTo(4.04, 0.0001));
    });

    test('Bus emissions match kBusEmission', () {
      expect(CO2Calculator.calculateTransport(10.0, VehicleType.bus), closeTo(0.89, 0.0001));
    });

    test('Electric car emissions match kElectricCarEmission', () {
      expect(CO2Calculator.calculateTransport(10.0, VehicleType.electric), closeTo(1.20, 0.0001));
    });
  });

  group('CO2Calculator Diet Tests', () {
    test('Vegan diet is the lowest carbon option', () {
      final vegan = CO2Calculator.calculateDiet(DietType.vegan);
      final veg = CO2Calculator.calculateDiet(DietType.vegetarian);
      final average = CO2Calculator.calculateDiet(DietType.average);
      final meat = CO2Calculator.calculateDiet(DietType.meatHeavy);

      expect(vegan < veg, true);
      expect(veg < average, true);
      expect(average < meat, true);
    });
  });

  group('CO2Calculator Energy Tests', () {
    test('Zero kWh should be zero emissions', () {
      expect(CO2Calculator.calculateEnergy(0.0), 0.0);
    });

    test('Negative kWh should return zero emissions', () {
      expect(CO2Calculator.calculateEnergy(-10.0), 0.0);
    });

    test('Energy emissions match kElectricityEmission factor', () {
      expect(CO2Calculator.calculateEnergy(100.0), closeTo(41.7, 0.0001));
    });
  });

  group('CO2Calculator Combined Total Tests', () {
    test('Aggregate total matches sum of components', () {
      final total = CO2Calculator.calculateTotal(
        distance: 10.0,
        vehicleType: VehicleType.car,
        dietType: DietType.vegan,
        electricityKwh: 20.0,
      );

      final expected = (10.0 * 0.404) + 2.89 + (20.0 * 0.417);
      expect(total, closeTo(expected, 0.001));
    });

    test('Aggregate total matches sum of components with Km', () {
      final total = CO2Calculator.calculateTotal(
        distance: 16.0934, // ~10 miles in km
        vehicleType: VehicleType.car,
        dietType: DietType.vegan,
        electricityKwh: 20.0,
        isKm: true,
      );

      final expected = (10.0 * 0.404) + 2.89 + (20.0 * 0.417);
      expect(total, closeTo(expected, 0.01));
    });
  });
}
