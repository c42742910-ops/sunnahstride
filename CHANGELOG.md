# SunnahStride Changelog

## v0.5.0 — Premium & Store Release Prep
*Released: 2026-03-05*

### 🆕 New: RevenueCat Integration
- Full in-app purchase system via RevenueCat
- **Apple Pay** and **Google Pay** appear automatically in the purchase sheet
- 3 plans: Monthly (EGP 399) · Yearly (EGP 3,299, save 30%) · Lifetime (EGP 7,999)
- Entitlement: `premium_access` gates all premium features
- Restore Purchases button on paywall and profile
- Subscription management sheet in Profile → shows active plan, cancel instructions
- Premium badge in profile updates dynamically: "Monthly Premium" / "Yearly Premium" / "Lifetime Premium"
- RevenueCat logout on sign-out (cross-device sync)
- Local cache prevents premium flash on app start

### 🆕 New: Premium Enforcement
- **Body fat %** exact value: Premium only (free users see 🔒)
- **Muscle mass** in kg: Premium only
- **Lean Body Mass**: Premium only
- **Body photo AI analysis**: Premium only (full privacy consent screen)
- **Halal scanner**: 10/day free → unlimited Premium
- **180 advanced workouts**: Premium only (free shows 10 basic)
- **AI meal planner**: Premium only

### 🆕 New: Platform Config
- `ios/Runner/Info.plist` — all camera/photo/notification permissions with correct descriptions
- `android/app/src/main/AndroidManifest.xml` — BILLING + CAMERA + INTERNET permissions
- `android/app/build.gradle` — minSdk 21, ProGuard rules for RevenueCat
- `android/app/proguard-rules.pro` — keeps RevenueCat & Flutter classes

### 🆕 New: Store Listing Pack
- `store_listing/APP_STORE_LISTING.md` — complete App Store & Google Play listing
  - App name, subtitle, 4000-char description (bilingual)
  - Keywords optimized for "halal", "حلال", "Muslim fitness"
  - In-app purchase table (all 3 products)
  - Screenshot guide (5 screens, sizes, design brief)
  - App icon design specs
  - 15-item submission checklist
  - App Review Notes for Apple
  - Pricing matrix: Egypt, Saudi, UAE, Jordan, USA, UK
  - ASO tips (App Store Optimization)
- `REVENUECAT_SETUP.md` — step-by-step RevenueCat configuration guide

### 🔧 Bug Fixes
- Profile screen: removed duplicate `PaywallScreen` class (was defined twice)
- Profile screen: version badge updated from 0.3 → 0.5
- Providers: `PremiumNotifier` now live-syncs with RevenueCat on app start
- Fitness screen: advanced plans upsell hidden if already premium

### 🏗️ Architecture
- `lib/core/revenuecat_service.dart` — complete RC service wrapper
  - `configure()` — call once from main.dart
  - `isPremium()` — checks live entitlement
  - `getOfferings()` — fetches live pricing, falls back to hardcoded
  - `purchase(offering)` — wraps purchasePackage with error handling
  - `restore()` — restores previous purchases
  - `getActivePlanId()` — returns monthly/yearly/lifetime/free
  - `setUserId()` / `logOut()` — for cross-device sync
- `rcOfferingsProvider` — FutureProvider for paywall live pricing
- `planNameProvider` — FutureProvider for profile plan badge

---

## v0.4.0 — AI Vision Features
*2026-03-05*
- AI Food Photo Analyzer (Claude Vision API)
- AI Body Photo Analyzer (Premium)
- Real AI Meal Planner (Nutrition tab)
- Recipe steps bug fix (String → List<String>)
- Models typing fixes

## v0.3.0 — Bilingual Complete
*2026-03-05*
- All 7 screens fully bilingual (Arabic ↔ English)
- 14-step onboarding
- Body metrics engine (15+ calculations)
- Nutrition tracker with Sunnah recipes
- Halal scanner

## v0.1–0.2 — Foundation
- Core architecture, navigation, theming
- Dark mode, RTL support
- SharedPreferences persistence
