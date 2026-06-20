// Transport: kg CO2 per mile
const double kCarEmission = 0.404;        // US EPA average passenger car
const double kBusEmission = 0.089;        // Transit bus average per passenger mile
const double kElectricCarEmission = 0.120; // US grid average electricity equivalent
const double kBikeEmission = 0.0;
const double kWalkEmission = 0.0;

// Diet: kg CO2 per day
const double kMeatHeavyDiet = 7.19;       // High meat consumption (>100g/day)
const double kAverageDiet = 4.67;         // Medium meat consumption (50-100g/day) or mixed diet
const double kVegetarianDiet = 3.81;      // No meat, dairy/eggs included
const double kVeganDiet = 2.89;           // No animal products

// Energy: kg CO2 per kWh
const double kElectricityEmission = 0.417; // US average electric grid CO2 factor
