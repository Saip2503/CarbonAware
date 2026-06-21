# CarbonAware — Carbon Footprint Awareness Platform

CarbonAware is a mobile-first web app that empowers individuals to track, understand, and actively reduce their daily environmental impact through frictionless logging and actionable, prioritized, AI-driven green recommendations.

---

## 🌍 Chosen Vertical
**Environmental Sustainability & Habit Building**
Our chosen vertical focuses on climate consciousness by providing individuals with a smart, frictionless daily logging tool to measure, track, and ultimately reduce their environmental impact.

---

## 🧠 Approach & Logic
The logic of this solution is built around the "Core Loop" of habit formation: 
1. **Awareness:** Users set a weekly baseline goal for $CO_2e$ reduction.
2. **Action:** Frictionless daily inputs (Transport, Diet, Energy) are instantly converted into scientifically backed $CO_2$ emission metrics using EPA conversion factors.
3. **Feedback:** A responsive dashboard visualizes progress against their weekly goals via charts, while an AI Insights Engine analyzes their specific historical logs to provide prioritized, contextual suggestions (e.g., if a user consistently drives a gas car, the engine suggests carpooling or public transit).

---

## ⚙️ How the Solution Works
1. **Onboarding & Auth:** Users sign up using Firebase Authentication (Google Sign-In or Email/Password) to create an isolated profile.
2. **Data Logging:** Users fill out a "Quick Log" containing sliders and dropdowns. This data is converted by the `CO2Calculator` and securely saved as a NoSQL document in Cloud Firestore.
3. **State & UI:** A Flutter-based front-end uses Riverpod to stream the user's logs in real-time, instantly updating the Dashboard's `fl_chart` Weekly Bar Charts and Goal Indicators.
4. **AI Generation:** The `InsightsEngine` aggregates recent logs and feeds them into the Gemini AI API (or falls back to deterministic rule-based algorithms) to deliver dynamic behavioral insights.

---

## 🤔 Assumptions Made
* **Broad Categorization for Frictionless UX:** We assume that speed of logging is more critical than hyper-precise data for habit building. Therefore, we categorized "Diet" into 4 broad types (Meat Heavy, Average, Vegetarian, Vegan) rather than itemized meal inputs.
* **Standardized US Averages:** We assume the user's baseline emissions roughly follow US Environmental Protection Agency (EPA) averages (e.g., `0.404 kg` $CO_2$ per passenger vehicle mile).
* **Linear Daily Energy:** We assume home energy (kWh) can be reasonably estimated by the user daily or derived linearly from their monthly electric bill.

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
│   │   ├── domain/
│   │   │   └── user_profile.dart # User Profile data model
│   │   ├── data/
│   │   │   └── auth_repository.dart # Sign In & Registration using Firebase Auth
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── auth_providers.dart # Riverpod Authentication State providers
│   │       └── views/
│   │           ├── goal_setup_screen.dart # Goal setup UI
│   │           ├── login_screen.dart # Login UI with Form validation
│   │           └── register_screen.dart # Register UI with profile creation
│   ├── logging/
│   │   ├── domain/
│   │   │   └── daily_log.dart    # Daily Log data model
│   │   ├── data/
│   │   │   └── log_repository.dart # Firestore Daily Log service
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── log_providers.dart # Riverpod Streams of user activity logs
│   │       └── views/
│   │           └── quick_log_screen.dart # Quick Log view with sliders and unit toggles
│   ├── dashboard/
│   │   └── presentation/
│   │       ├── views/
│   │       │   └── dashboard_screen.dart # Dashboard UI summarizing logs
│   │       └── widgets/
│   │           ├── category_breakdown.dart # Donut Chart with Category Breakdown (fl_chart)
│   │           ├── goal_indicator.dart # Circular Progress indicator
│   │           └── weekly_chart.dart # Weekly Emissions Bar Chart (fl_chart)
│   └── insights/
│       ├── domain/
│       │   └── insight.dart      # Insight data model & priority enums
│       ├── data/
│       │   ├── ai_service.dart   # Generative AI tip builder
│       │   └── insights_engine.dart # Smart logic engine aggregating user stats
│       └── presentation/
│           ├── providers/
│           │   ├── insights_provider.dart # Riverpod AI Insights provider
│           │   └── insight_providers.dart # Riverpod Rule-based Insights provider
│           └── views/
│               ├── insight_card.dart # UI card displaying AI/fallback insights
│               └── insights_panel.dart # Insights UI panel presenting prioritized tips
└── navigation/
    └── app_router.dart       # GoRouter configuration with Auth Guards
```

---

## ⚡ Performance & Web Efficiency
To optimize memory, CPU, and rendering performance on the web target (addressing typical Flutter Web overhead), the platform employs several state-of-the-art strategies:
1. **WASM Compilation Target:** We build and deploy the app using the new `--wasm` compilation target (`flutter build web --wasm`). Compiling to WebAssembly significantly reduces CPU overhead, optimizes garbage collection, and ensures near-native UI frame rates.
2. **Instant inline CSS Splash Screen:** In `web/index.html`, we've embedded a lightweight inline CSS splash screen that renders immediately while the heavy Dart runtime (`main.dart.js` / WASM) is loading. This dramatically reduces First Contentful Paint (FCP) and improves the perceived speed.
3. **Resource Preconnecting:** We preconnect to external font hosting services (such as `fonts.gstatic.com`) directly in the HTML header to eliminate network layout shifting during startup.
4. **Riverpod Granular Rebuilds:** Widgets listen to specific, narrow state providers to minimize rebuild cycles, keeping garbage collection cycles short and reducing memory consumption under profiling tools.

---

## ⚙️ Setup & Execution Instructions

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
