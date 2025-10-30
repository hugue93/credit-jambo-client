# Credit Jambo Client (Flutter)

Customer-facing Flutter app for registration, login, device verification, balance, transactions, password reset, and push notifications.

## Requirements
- Flutter SDK 3.x
- Node.js backend running (see `/backend`)
- Firebase project (Firestore + Cloud Messaging)
- Android Studio for Android emulator/USB device
- iOS builds require macOS + Xcode (not available on Windows)

## Backend environment (.env)
Create `backend/.env`:

PORT=3000
CORS_ORIGINS=http://localhost:5173,http://localhost:5174
JWT_SECRET=replace-with-strong-secret
PASSWORD_PEPPER=replace-with-strong-pepper
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=service-account@your-project-id.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"VITE_API_BASE_URL=http://localhost:3000
VITE_VAPID_KEY=YOUR_PUBLIC_VAPID_KEY

Start backend:

cd backend
npm install
npm run dev

API Docs (if enabled in backend): http://localhost:3000/docs

## Firebase (client)
- Get Web Push (VAPID) key: Firebase Console → Project settings → Cloud Messaging → Web configuration.
- Web config is included in `web/index.html`. Replace with your own if needed.
 - For testing, you can use: `FCM_VAPID_KEY=VITE_VAPID_KEY

## Run (Web)
Fixed port 5173 and pass API/VAPID:

flutter run -d chrome --web-hostname=localhost --web-port=5173 --dart-define=API_BASE_URL=http://localhost:3000 --dart-define=FCM_VAPID_KEY=VITE_VAPID_KEY

If you change ports, update `CORS_ORIGINS`.

## Run (Android Emulator / Device)
- Android Emulator (host loopback):

flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:3000 --dart-define=FCM_VAPID_KEY=VITE_VAPID_KEY

- Genymotion:

flutter run -d <genymotion-id> --dart-define=API_BASE_URL=http://10.0.3.2:3000 --dart-define=FCM_VAPID_KEY=VITE_VAPID_KEY

- Real device (LAN IP):

flutter devices
flutter run -d <device-id> --dart-define=API_BASE_URL=http://<your-lan-ip>:3000 --dart-define=FCM_VAPID_KEY=VITE_VAPID_KEY

- Real device via USB reverse (use localhost):

adb reverse tcp:3000 tcp:3000
flutter run -d <device-id> --dart-define=API_BASE_URL=http://localhost:3000 --dart-define=FCM_VAPID_KEY=VITE_VAPID_KEY

## Features
- Auth (register/login), SHA-512 + pepper, JWT + refresh
- Device registration and admin verification
- Dashboard (balance, recent transactions)
- Deposit and Withdraw with validation
- Low balance banner and push alerts (< 5,000 RWF)
- Password reset flow (6-digit code)
- FCM notifications (deposit, withdraw, low balance, device verified, login)

## Client API Endpoints
- POST `/auth/register`
- POST `/auth/login`
- POST `/auth/refresh`
- POST `/auth/forgot-password`
- POST `/auth/reset-password`
- POST `/devices/register-by-email`
- POST `/devices/push-token`
- GET `/account/balance`
- GET `/transactions`
- POST `/transactions/deposit`
- POST `/transactions/withdraw`

## Assumptions
- Single backend serves both client and admin routes.
- Only verified devices can login; non-verified flows show guidance.
- Firestore indexes may be needed (create via Console when prompted).

## Database access
- Firestore access is restricted. If you need database access for testing, send your Google account email to the maintainer so permissions can be granted in Firebase/IAM.

## Troubleshooting
- 401 Unauthorized: token expired → re-login.
- No web notifications: allow site permission, ensure service worker registered.
- Mobile cannot reach backend: use `10.0.2.2` (emulator), LAN IP or `adb reverse` (USB).
