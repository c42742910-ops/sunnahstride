# RevenueCat Setup Guide — SunnahStride v0.5
## Takes 15–20 minutes. Do this ONCE before your first release.

---

## Step 1 — Create RevenueCat Account
1. Go to **https://app.revenuecat.com** → Sign Up (free)
2. Create project → name it **SunnahStride**

---

## Step 2 — Add Your App

### iOS:
1. Projects → SunnahStride → **+ Add App** → iOS
2. Bundle ID: `com.yourname.sunnahstride`
3. App name: `SunnahStride`
4. App Store Connect API key: paste from App Store Connect → Users & Access → Keys

### Android:
1. + Add App → Google Play
2. Package name: `com.yourname.sunnahstride`
3. Service Account JSON: download from Google Play Console → Setup → API access

---

## Step 3 — Create Products

Go to **Products** → + New Product:

| Product ID                           | Type              | Price (EGP) |
|-------------------------------------|-------------------|-------------|
| `sunnahstride_premium_monthly`       | Subscription      | 399 / month |
| `sunnahstride_premium_yearly`        | Subscription      | 3,299 / year|
| `sunnahstride_premium_lifetime`      | Non-consumable    | 7,999       |

> ⚠️ Create these products in App Store Connect AND Google Play Console FIRST,
> then add the same IDs here in RevenueCat.

---

## Step 4 — Create Entitlement

**Entitlements** → + New Entitlement:
- Identifier: `premium_access`
- Attach all 3 products above to this entitlement

---

## Step 5 — Create Offering

**Offerings** → + New Offering:
- Identifier: `default`
- Add packages:
  - Monthly package → `sunnahstride_premium_monthly`
  - Annual package  → `sunnahstride_premium_yearly`
  - Lifetime package→ `sunnahstride_premium_lifetime`

---

## Step 6 — Get Your API Keys

**Project Settings** → **API Keys**:
- Copy `Apple App-Specific Shared Secret` (starts with `appl_`)
- Copy `Google Play Public API Key` (starts with `goog_`)

---

## Step 7 — Add Keys to Your Code

Open `lib/core/revenuecat_service.dart` and replace:

```dart
static const appleApiKey  = 'appl_REPLACE_WITH_YOUR_APPLE_KEY';
static const googleApiKey = 'goog_REPLACE_WITH_YOUR_GOOGLE_KEY';
```

With your actual keys from Step 6.

---

## Step 8 — Test in Sandbox

### iOS:
1. Settings app → App Store → Sandbox Account → create test Apple ID
2. Run app on device (not simulator)
3. Tap Upgrade → Apple Pay sheet appears automatically ✅

### Android:
1. Play Console → License Testing → add your Gmail as tester
2. Run app on device
3. Tap Upgrade → Google Pay sheet appears automatically ✅

---

## Step 9 — Verify Purchase Works

After tapping Upgrade in sandbox:
1. Complete payment with test account
2. App should show Premium badge ⭐ in profile
3. Body fat % should unlock
4. Body photo analysis should unlock

---

## How Premium Gating Works in the Code

```
User taps Upgrade
    ↓
PaywallScreen → RevenueCatService.purchase(offering)
    ↓
purchases_flutter opens Apple/Google Pay sheet
    ↓
On success → customerInfo.entitlements.active contains 'premium_access'
    ↓
PremiumNotifier.onPurchaseSuccess() → state = true, saved to SharedPreferences
    ↓
All screens watching premiumProvider rebuild → premium features unlock
```

## What Gets Unlocked:
| Feature                    | Free | Premium |
|---------------------------|------|---------|
| BMI calculation            | ✅   | ✅      |
| Body fat % exact           | 🔒   | ✅      |
| Muscle mass                | 🔒   | ✅      |
| Lean Body Mass             | 🔒   | ✅      |
| AI food photo analysis     | 10/day | ✅ unlimited |
| AI body photo analysis     | 🔒   | ✅      |
| Halal scanner              | 10/day | ✅ unlimited |
| Advanced workouts          | 10 basic | 180 full |
| AI meal planner            | 🔒   | ✅      |
| Full nutrition history     | 🔒   | ✅      |

---
*Keep your API keys private — never commit to Git!*
*Add `lib/core/revenuecat_service.dart` to `.gitignore` or use environment variables.*
