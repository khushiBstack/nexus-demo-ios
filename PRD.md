# Product Requirements Document — Nexus Demo (iOS)

**Platform:** iOS (SwiftUI) · **Bundle/Target:** `nexus-demo` · **Status:** Derived from current source (≈8.5k LOC, 30+ Swift files)

---

## 1. Overview

Nexus Demo is a multi-domain iOS showcase and test-bed app. It bundles four simulated industry apps (E-commerce, Healthcare, BFSI/Banking, Travel) plus a **Standalone Demo** hub of device-capability test screens. All data is sample/mock data; no real payments, medical records or bookings occur.

### 1.1 Purpose
- Provide realistic, end-to-end user journeys across verticals for demos and automated/manual mobile testing.
- Expose hard-to-test device capabilities (camera, biometrics, microphone, GPS, network, push, files, OTP) as isolated, easily reachable screens.

### 1.2 Goals
1. Demonstrate realistic flows (login → OTP → browse → pay → confirm) per industry.
2. Offer one-tap access to individual device features for QA and tooling validation (e.g. media injection, biometric simulation, network throttling).
3. Be automation-friendly: stable accessibility labels/identifiers on key elements.

### 1.3 Non-Goals
- Real backend, real payments, real medical/financial data, or production authentication.
- Android or web clients.

### 1.4 Target Users
| Persona | Need |
|---|---|
| QA / test engineer | Deterministic screens to exercise device features and flows |
| Sales / solutions engineer | Polished multi-vertical demo of mobile testing |
| Developer | Reference implementations of iOS capability integrations |

---

## 2. App Structure & Navigation

- **Entry:** `DomainSelectionView` ("Nexus Demo") inside a `NavigationStack`. Tiles: **E-commerce**, **Healthcare**, **BFSI**, **Travel**, and **Standalone demo**.
- **Global services (environment objects):** `SessionStore` (per-domain login/OTP state), `BFSIStore` (accounts, transactions, connectivity), `ThemeManager` (dark mode), `IPGeoManager` (public-IP location badge).
- **Global behaviours:**
  - Shake device → toggles light/dark theme, shows a "shake theme" toast (`shakeThemeToast`); preference persisted in `UserDefaults`.
  - Foreground notifications display as banner + sound + badge.
  - Content constrained to readable width on iPad (`ReadableWidthModifier`).

---

## 3. Functional Requirements

### 3.1 Authentication (all domains)
| ID | Requirement |
|---|---|
| AUTH-1 | Industry login (`IndustryLoginView`) accepts email + password; **Sign In** enabled only when email contains "@" and password is non-empty; invalid email shows "Enter a valid email address". |
| AUTH-2 | "Sign in with Face ID" uses `LocalAuthentication`; button disabled while authenticating; failures surface an error message. |
| AUTH-3 | Display name is derived from email local part (e.g. `jane.doe@x.com` → "Jane Doe"). |
| AUTH-4 | Login and OTP-verified state are tracked per domain in `SessionStore`. |
| AUTH-5 | BFSI uses a dedicated `LoginView` ("DemoBank") with the same email/password + Face ID options. |

### 3.2 OTP Verification
| ID | Requirement |
|---|---|
| OTP-1 | User enters phone number; app requests a code via **Twilio Verify**. |
| OTP-2 | 6-digit code entry via individual digit boxes; shows "Verified successfully ✓" on success. |
| OTP-3 | "Resend OTP" gated by a countdown ("Resend in Ns"). |
| OTP-4 | If Twilio credentials are placeholders (`TWILIO_*`), the app runs in **demo mode**: banner "Twilio not configured — enter any 6 digits to demo". |
| OTP-5 | Send/verify states modelled (`OTPSendState`, `OTPVerifyState`) with error handling for network/config errors. |

### 3.3 E-commerce ("ShopNexus")
Tabs: **Shop**, **Search**, **Cart**, **Orders**.
- Shop home: greeting ("Hello, {firstName}"), Featured products, product cards with rating/review count.
- Product detail; add to cart with quantity.
- Search: free-text with empty ("Search for products") and no-result ("No results for: …") states.
- Cart: line items, Subtotal, Shipping (free-shipping threshold message), Tax (8%), **Proceed to Checkout**; empty state "Your cart is empty".
- Checkout: delivery address (manual entry or **Use my current location** via Core Location + reverse geocoding), order summary, payment (Apple Pay button / alternative).
- Order confirmation ("Order Placed!", short order ID), **Receipt** with share sheet, Continue Shopping.
- Order history; empty state "No orders yet".
- Entry gated by e-commerce login + OTP.

### 3.4 Healthcare ("CareNexus")
Tabs: **Home**, **Appointments**, **Health Records**, **Nearby**.
- Patient home: "Stay healthy today", quick actions, upcoming appointments, active prescriptions, recent lab results.
- Appointments: list/detail, **Book Appointment** sheet, cancel.
- Appointment payment: Apple Pay / other methods → "Payment Confirmed".
- Prescriptions and lab-result detail views.
- Health records: document upload via document picker.
- Nearby providers: location-based list (sample data) with **Locate** action.
- Entry gated by healthcare login + OTP.

### 3.5 BFSI / Banking ("DemoBank")
Tabs: **Accounts**, **Transfer**, **Pay**, **KYC**, **Profile**.
- **Accounts/Dashboard:** welcome header, four sample accounts (Checking, Savings, Credit Card, Investment) with masked numbers and currency-formatted balances; account detail with Transaction History (empty state "No transactions"); **Download Statement (PDF)** with period picker and share sheet; "ATMs Near Me" entry.
- **Transfer:** pick source account, recipient, amount keypad ("$amount"), **Review Transfer** → **Send**; transfers fail if balance is insufficient; successful transfer updates balance and logs a transaction.
- **Apple Pay:** select account, merchant, amount; payment debits account and records "Apple Pay – {merchant}"; Recent Apple Pay list.
- **KYC (Identity Verification):** multi-step — intro ("Verify Your Identity" / Start Verification) → document capture (camera) → liveness ("Position your face in the circle") → review ("Review and Submit") → "Verification Submitted!". Completion stored in `kycCompleted`.
- **Investments:** portfolio value, allocation, holdings (sample data).
- **ATM locator:** map (iOS 17+) and list of nearby ATMs with search; states for searching, no results, and location-permission denied.
- **Profile:** user info, change profile photo (Take Photo / Choose from Library; id `changeProfilePicture`), Change Password (placeholder screen), send-alerts control (`sendAlertsButton`).
- **Connectivity banner:** red/green top banner on network loss/restore; Dashboard shows "You are offline. Some features may be unavailable."
- BFSI OTP tracked via `bfsiOTPVerified`.

### 3.6 Travel ("TripNexus")
- Home: "Where to next?", Hot Deals, Upcoming Trips, Recent Bookings.
- Search tabs for **Flights** (origin/destination, depart, passengers) and **Hotels** (destination, check-in, nights, guests); "Use current location" prefill; 3 sample results each.
- Flight and hotel detail (amenities, price per person/night).
- Booking with payment (Apple Pay / other) → Booking Confirmed.
- **My Trips** and **Digital Key** (hotel room key, "Room N").
- Entry gated by travel login + OTP.

### 3.7 Standalone Demo (11 device-feature tests)
Each is reachable directly without domain login; screen also shows network status.

| # | Feature | Behaviour |
|---|---|---|
| 1 | Image injection | Capture still via camera; show selected image / "No image selected" |
| 2 | Biometric test | Trigger Face ID/Touch ID prompt, show result, Reset |
| 3 | Video injection | Record + play video; "No video selected" state |
| 4 | File upload & download | Pick any file; download sample PDF; Save to Files / share |
| 5 | Audio injection | Pick audio file from Files; play ("Playing…") / record |
| 6 | IP geolocation | Public IP → location via `ipapi.co` (HTTPS); Clear Results |
| 7 | Network test | Connection status, interface, cellular/expensive warning |
| 8 | GPS test | Exact coordinates + reverse-geocoded address |
| 9 | OTP test | Send + verify code (Twilio or demo mode) |
| 10 | Push notifications | Request permission, compose title/body, schedule with delay slider, list scheduled, in-app banner (`notification_banner*` ids) |
| 11 | QR code scanner | Camera scan → result screen (`qr_result_text`) |

### 3.8 Shared Components
- **Network speed widget / detail sheet:** online/offline/cellular status, interface details.
- **IP location badge:** shows detected public-IP location app-wide.
- **Theme:** system-independent dark mode toggled by shake.

---

### 3.9 Location-Based Behaviour

Two location sources feed the app: **IP geolocation** (`IPGeoManager`, `https://ipapi.co/json/`, no permission needed, fetched once per launch via `fetchIfNeeded()`) and **device GPS** (Core Location, "When In Use" permission, with reverse geocoding via `CLGeocoder`).

| ID | Area | Location-driven behaviour | Source |
|---|---|---|---|
| LOC-1 | Global | `IPGeoManager` exposes city, region, country, country code and IP; `IPLocationBadge` shows "{city or country}" (VoiceOver: "IP location: …"). | IP |
| LOC-2 | Global | `bestCity` = GPS city if available, otherwise IP city. ATM search publishes its GPS city to `IPGeoManager.gpsCity` so other screens match. | GPS → IP |
| LOC-3 | Global | `currencyCode` maps country to a currency (US→USD, GB→GBP, EU countries→EUR, IN→INR, JP→JPY, AU→AUD, CA→CAD, SG→SGD, AE→AED, default USD). Note: most screens still hard-code USD, so this is not yet applied everywhere. | IP |
| LOC-4 | E-commerce | Shop home shows the user's city (or country) label and a "Deals in {city}" banner (fallback "your city"). | IP |
| LOC-5 | E-commerce | Checkout "Use my current location" detects the delivery address (street, city) via GPS + reverse geocoding; "Detecting…" shown while locating; manual entry is the alternative. | GPS |
| LOC-6 | Healthcare | Nearby tab requests location on appear and via **Locate**; the provider list (name, type, distance) is **static sample data** (Urgent Care 0.8 mi, Hospital 1.4 mi, Pharmacy 0.3 mi) and does not change with the real location. | GPS (permission only) |
| LOC-7 | BFSI | ATM locator uses GPS, reverse-geocodes the city ("Showing ATMs near {city}"), and runs live MapKit searches for ATMs and banks near the user, with distance per result and a map centred on the user (2 km span). | GPS + MapKit |
| LOC-8 | BFSI | ATM states: searching ("Finding ATMs near you…"), none found, permission denied ("Please enable location access in Settings."), map unavailable below iOS 17. | GPS |
| LOC-9 | BFSI | With no user location, the map falls back to a fixed coordinate (37.3318, -122.0312, Cupertino). | Fallback |
| LOC-10 | Travel | Home shows "Departing from {city or country}". Search offers a "Use current location: {city}" button that fills **origin** (Flights tab) or **destination** (Hotels tab). | IP |
| LOC-11 | Travel | Hotel results are generated from the destination text ("Grand {city} Hotel", "{city} Boutique Inn", …); defaults to "Tokyo" when empty. | User input |
| LOC-12 | Standalone | GPS test returns exact coordinates and a reverse-geocoded address (locality, state, postal code, country). | GPS |
| LOC-13 | Standalone | IP geolocation test shows IP, country, region and city; supports Clear Results. | IP |
| LOC-14 | Payments | Apple Pay requests are fixed to country `US` and currency `USD` regardless of location. | Static |

**Not location-dependent:** banking balances, transfers, KYC, OTP, push notifications, pricing and tax (a fixed 8% in e-commerce).

**Testing implications:** IP-based features follow the network's egress location (relevant for cloud devices and VPNs), while GPS features follow the device's simulated location, so the two can disagree. Setting a device location changes ATM results, the checkout address and the GPS test, but not the IP-derived labels in Shop, Travel or the badge.

---

## 4. Non-Functional Requirements

| Area | Requirement |
|---|---|
| Platform | iOS, SwiftUI; map features require iOS 17+ (graceful fallback "Map requires iOS 17+") |
| Privacy permissions | Camera, Microphone, Face ID, Location When In Use (usage strings in `Info.plist-additions.md`) |
| Networking | HTTPS only; no ATS exceptions; Twilio Verify REST and ipapi.co are the only external calls |
| Accessibility | Decorative icons hidden from VoiceOver; key controls labelled; identifiers for automation |
| Layout | iPhone and iPad (readable-width constraint on large screens) |
| Resilience | Offline banner; permission-denied and empty states on all list/location screens |
| Security | Twilio SID/token must not ship hard-coded in production builds (currently placeholder constants — move to secure config) |
| Testability | Deterministic sample data; UI test target `nexus-demoUITests` |

---

## 5. Data Model Summary
- **Session:** per-domain `loggedIn`, `userName`, `userEmail`, `otpVerified`; BFSI `kycCompleted`.
- **BFSI:** `BFSIAccount` (name, number, balance, type, currency), `BFSITransaction`, `ApplePayRecord`.
- **E-commerce:** `Product`, `CartItem`, `PlacedOrder`.
- **Healthcare:** `Appointment`, `Prescription`, `LabResult`, `HealthRecord`, `NearbyProvider`.
- **Travel:** `FlightResult`, `HotelResult`, `TravelBooking`, `TripStatus`.
- **Persistence:** only the theme preference (`appIsDarkMode`) persists; all other state is in-memory and resets on relaunch.

---

## 6. Acceptance Criteria (high level)
1. From launch, each of the 5 tiles navigates to its experience.
2. Login rules (AUTH-1) enforced; Face ID path works on a device/simulator with biometrics enrolled.
3. OTP completes in both Twilio-configured and demo modes.
4. A BFSI transfer reduces the source balance by the amount, adds a transaction, and rejects overdrafts.
5. KYC completes all steps and marks verification as submitted.
6. All 11 standalone features open and show their empty/initial state, then respond to input or injected media.
7. Shaking the device toggles theme and shows the toast.
8. Losing connectivity shows the offline banner; restoring shows online state.

---

## 7. Risks, Gaps & Open Questions
- Twilio credentials are placeholders; OTP runs in demo mode until configured.
- Change Password is a placeholder screen (no backend).
- Nearby providers / ATMs / investments use sample data despite location wiring.
- No persistence beyond theme; orders, bookings and transfers reset on relaunch.
- Apple Pay flows are simulated; merchant/entitlement setup needed for real sheets.
- Open: Should state persist across launches? Should login validate against a mock backend? Localisation scope?

---

## 8. Future Considerations
Persistent storage, real auth backend, localisation, Android parity, expanded UI-test coverage per domain flow.
