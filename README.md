## Client Application (Flutter + Node)

Structure:> frontend (Flutter), backend (Node), .env.example, README.md

Backend:> cd backend & npm install & copy .env.example .env & npm run dev
Frontend Web:> cd frontend & flutter pub get & flutter run -d chrome --web-hostname=localhost --web-port=5175 --dart-define=API_BASE_URL=http://localhost:3000
Frontend Android:> flutter run -d <android-device-id> --dart-define=API_BASE_URL=http://<your-ip>:3000
