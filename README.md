## Client Application (Flutter + Node)

Structure:> frontend (Flutter), backend (Node), .env.example, README.md

Backend:> cd backend & npm install &  npm run dev
Frontend Web:> cd frontend & flutter pub get & flutter run -d chrome --web-hostname=localhost --web-port=5173 --dart-define=API_BASE_URL=http://localhost:3000 --dart-define=FCM_VAPID_KEY=VITE_VAPID_KEY

Frontend Real Android device using USB:> adb reverse tcp:3000 tcp:3000
flutter run -d <device-id> --dart-define=API_BASE_URL=http://localhost:3000 --dart-define=FCM_VAPID_KEY=VITE_VAPID_KEY

Frontend Android Emulator (host loopback):> flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:3000 --dart-define=FCM_VAPID_KEY=VITE_VAPID_KEY
