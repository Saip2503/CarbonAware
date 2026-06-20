# CarbonAware — Carbon Footprint Awareness Platform

CarbonAware is a mobile-first web app that empowers individuals to track, understand, and actively reduce their daily environmental impact through frictionless logging and actionable, prioritized, AI-driven green recommendations.

---

## 🌍 Chosen Vertical & Challenge Focus
* **Vertical**: Environmental Sustainability & Habit Building
* **Core Objective**: To provide a simple, scientific, and low-friction interface for logging daily carbon-producing habits and displaying clear Weekly Charts, category-wise breakdowns, and real-time progress relative to personal carbon targets.

---

## 🏗️ Architecture Context
Designed as a serverless, mobile-first web app using Flutter for the UI and Firebase services as the backend:

```
[ Flutter Web / App Shell ]
          │ (Riverpod State Management)
          ▼
┌──────────────────┐       ┌────────────────────┐
│  Firebase Auth   │       │  Cloud Firestore   │
│  (User Sign-In)  │       │ (User Daily Logs)  │
└──────────────────┘       └────────────────────┘
```

* **Authentication**: Firebase Auth (email/password validation flow).
* **Database**: Cloud Firestore. Daily logs are stored under the sub-collection: `users/{userId}/daily_logs/{YYYY-MM-DD}`.
* **State Management**: standard manual Riverpod streams (`StreamProvider` and `Provider`) to stream real-time logs and user profiles to the UI.

---

## 🧮 CO2 Conversion Calculations & Sources
The calculation engine converts raw daily activity metrics into kilograms of $CO_2$ equivalent ($kg\text{ }CO_2e$) using scientific conversion factors:

### 1. Transportation ($kg\text{ }CO_2e$ per mile)
* **Gasoline Car**: `0.404` (US EPA average passenger vehicle factor)
* **Electric Car**: `0.120` (US electric grid average greenhouse gas factor equivalent)
* **Public Bus**: `0.089` (Average transit bus emissions per passenger mile)
* **Active Transit (Bicycle/Walking)**: `0.000` (Zero emissions)

### 2. Dietary Footprint ($kg\text{ }CO_2e$ per day)
* **Meat Heavy**: `7.19` (High meat consumption, dairy, eggs)
* **Average/Mixed**: `4.67` (Medium meat consumption, dairy, eggs)
* **Vegetarian**: `3.81` (Dairy and eggs, no meat)
* **Vegan**: `2.89` (100% plant-based, no animal products)

### 3. Home Energy ($kg\text{ }CO_2e$ per kWh)
* **Electricity Consumption**: `0.417` (US average electric grid CO2 factor per kWh)

### Combined Emission Formula:
$$Total\text{ }CO_2e\text{ }(kg) = (Miles \times Factor_{Vehicle}) + Factor_{Diet} + (kWh \times 0.417)$$

---

## 📂 Project Structure
```
lib/
├── main.dart                 # App initialization & Firebase setup
├── app.dart                  # Material App shell configuration
├── firebase_options.dart     # Firebase configuration template
├── core/
│   ├── constants/
│   │   ├── app_colors.dart   # Forest Green design system colors
│   │   ├── app_theme.dart    # Custom dark mode styles with Outfit & Inter fonts
│   │   └── emission_factors.dart # Conversion constants (EPA-based)
│   └── utils/
│       └── co2_calculator.dart   # Conversion logic engine (pure functions)
├── features/
│   ├── auth/
│   │   ├── data/auth_repository.dart     # Sign In & Registration using Firebase Auth
│   │   ├── models/user_profile.dart      # User Profile data model
│   │   ├── providers/auth_providers.dart # Riverpod Authentication State providers
│   │   └── views/
│   │       ├── login_screen.dart         # Login UI with Form validation
│   │       └── register_screen.dart      # Register UI with profile creation
│   ├── logging/
│   │   ├── data/log_repository.dart      # Firestore Daily Log sub-collection service
│   │   ├── models/daily_log.dart         # Daily Log data model
│   │   ├── providers/log_providers.dart  # Riverpod Streams of user activity logs
│   │   └── views/quick_log_screen.dart   # Quick Log view with sliders and real-time estimate
│   ├── dashboard/
│   │   ├── views/dashboard_screen.dart   # Dashboard summarizing logs, weekly chart, and goal progress
│   │   └── widgets/
│   │       ├── weekly_chart.dart         # Weekly Emissions Bar Chart (fl_chart)
│   │       ├── category_breakdown.dart   # Donut Chart with Category Breakdown (fl_chart)
│   │       └── goal_indicator.dart       # Circular Progress indicator comparing daily goal
│   └── insights/
│       ├── data/insights_engine.dart     # Smart logic engine aggregating user stats
│       ├── models/insight.dart           # Insight data model & priority enums
│       ├── providers/insight_providers.dart # Riverpod Insights providers
│       └── views/insights_panel.dart     # Insights UI presenting prioritized saving tips
└── navigation/
    └── app_router.dart       # GoRouter configuration with Auth Guards
```

---

## ⚡ Setup & Execution Instructions

### Prerequisites
* Flutter SDK (version `3.32.8` or compatible)
* A Firebase Project configured with Authentication (email/password) and Cloud Firestore

### Getting Started

1. **Clone the repository:**
   ```bash
   git clone <repository_url>
   cd "Carbon Footprint Awareness Platform"
   ```

2. **Retrieve dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase:**
   Ensure Firebase CLI is installed and configure it:
   ```bash
   flutterfire configure
   ```
   *This will update `lib/firebase_options.dart` automatically.*

4. **Run the app locally:**
   ```bash
   flutter run
   ```

5. **Run the test suite:**
   ```bash
   flutter test
   ```
