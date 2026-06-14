# TaskGuard AI — Complete Project Guide

---

## 1. What Is TaskGuard AI?

TaskGuard AI is a smart mobile task-management app built with **Flutter** (frontend) and **Node.js + PostgreSQL** (backend). It goes beyond a normal to-do list by using an AI assistant to protect users from burnout, suggest the best times to work, and give productivity insights.

### Core Goals
| Goal | How It Is Achieved |
|---|---|
| Smart task management | Create, schedule, prioritize, and complete tasks with AI-assisted ordering |
| Burnout protection | AI monitors your workload and sends gentle reminders when overload is detected |
| Focus sessions | Built-in Pomodoro-style timer with session tracking |
| Productivity insights | Daily/weekly scores, peak-hour analysis, completion streaks |
| AI chat assistant | Conversational AI (via OpenRouter) for planning help, task analysis, and suggestions |
| Offline-first | All key data is cached locally (Hive); tasks created offline sync when back online |
| Push notifications | Firebase Cloud Messaging sends task reminders to the device |

---

## 2. System Architecture

```
┌─────────────────────────────────┐
│        Flutter App (Mobile)      │
│  ┌──────────┐  ┌──────────────┐ │
│  │  Screens │  │   Services   │ │
│  │  Home    │  │  TaskService │ │
│  │  Chat    │  │  AiService   │ │
│  │  Focus   │  │  AuthService │ │
│  │  Insights│  │  ApiClient   │ │
│  │  Calendar│  │  LocalStorage│ │
│  │  Settings│  │  (Hive cache)│ │
│  └──────────┘  └──────┬───────┘ │
└─────────────────────── │ ────────┘
                         │ HTTP (Dio)
                         ▼
┌─────────────────────────────────┐
│     Node.js / Express Backend    │
│  Routes: /auth /tasks /ai        │
│           /insights /focus       │
│           /notifications         │
│  JWT Auth + Refresh Tokens       │
│  Rate Limiting + Helmet          │
└──────────────┬──────────────────┘
               │ Prisma ORM
               ▼
┌─────────────────────────────────┐
│         PostgreSQL Database      │
│  Tables: User, Task, Subtask,    │
│  FocusSession, ProductivityData, │
│  ChatMessage, Notification,      │
│  Reminder                        │
└─────────────────────────────────┘

External Services
├── OpenRouter API  → AI chat + overload analysis
├── Firebase Admin  → Push notifications (FCM)
└── Google Auth     → Google Sign-In
```

---

## 3. App Screens and Features

### Authentication
- **Splash Screen** — checks if user is logged in; routes to home or onboarding
- **Onboarding** — introduction slides with "Get Started" button
- **Register** — full name, email, password; also supports Google Sign-In
- **Login** — email + password or Google Sign-In; JWT tokens stored securely

### Home Screen
- Greeting by time of day ("Good Morning, [Name]")
- Circular productivity score gauge (0–100%)
- Smart Suggestions panel (AI-powered: Deep Work Block, Recharge Time)
- Upcoming tasks list (today's tasks, up to 5 shown)
- FAB (+) button to create a new task
- Offline banner appears at the top when the device cannot reach the server
- Burnout dialog appears automatically when AI detects HIGH overload level

### Task Management (New Task Screen)
- Title, description, due date, start time
- Priority: LOW / MEDIUM / HIGH / URGENT
- Category (Work, Personal, Health, etc.)
- Estimated duration
- Recurrence: Daily, Weekly, Monthly, Custom
- Subtasks (add multiple)
- Reminder time
- NLP input — type naturally ("Meeting tomorrow at 3pm") and AI parses it

### AI Chat Screen
- Full conversation with the AI assistant
- Ask anything: "What should I focus on today?", "Analyze my productivity", "Suggest time blocks"
- Chat history is cached locally and synced with the server
- Settings icon top-right leads to app settings

### Focus Timer Screen
- Pomodoro-style timer (default 25 minutes)
- Start / Pause / Reset controls
- Session is recorded in the database when completed

### Insights Screen
- Weekly productivity chart (bar chart)
- Peak activity hours
- Completion rate
- Focus minutes logged

### Calendar Screen
- Monthly calendar view
- Tap a day to see tasks scheduled for that date

### Settings
- **Profile** — edit display name (email is read-only)
- **Notifications** — toggle task reminders, daily summaries, burnout alerts
- **Theme** — Light / Dark / Pink Precision
- **Privacy** — data sharing toggles, export data, delete account
- **Sign Out** — clears tokens, returns to onboarding

---

## 4. How to Use the App (User Guide)

### First Time
1. Open the app → tap **Get Started** on the onboarding screen
2. Tap **Register** → fill in your name, email, and password (min 8 characters) → tap **Create Account**
3. You are taken directly to the Home screen

### Creating a Task
1. Tap the **pink + button** (bottom right of Home screen)
2. Fill in the title at minimum; add details as needed
3. Tap **Create Task** — it appears in your task list instantly

### Completing a Task
- On the Home screen, tap the circle icon on the right side of any task
- The title gets a strikethrough and the task is marked complete on the server

### Using the AI Chat
1. Tap the chat bubble icon in the bottom navigation bar
2. Type your message and tap send
3. The AI responds with suggestions, analysis, or answers

### Starting a Focus Session
1. On the Home screen, tap **Accept Suggestion** on the "Deep Work Block" card, OR tap the timer icon in the bottom nav
2. Tap **Start** — the 25-minute countdown begins
3. When done, the session is saved to your productivity history

### Offline Use
- If the server is unreachable, a grey banner says "Offline — showing cached data"
- You can still **view tasks** and **complete tasks** — changes are queued
- When you go back online, the app syncs your queued actions automatically

---

## 5. Transferring the Project to Another Machine

### What the Other Machine Needs (Install These First)

There are two ways to run the backend. **Docker is the easiest** — it handles PostgreSQL automatically.

#### Option A — Docker (Recommended, fewer steps)
| Software | Download |
|---|---|
| Flutter SDK 3.22+ | https://flutter.dev/docs/get-started/install |
| Android Studio (latest) | https://developer.android.com/studio |
| Java JDK 17+ | https://adoptium.net |
| Docker Desktop | https://www.docker.com/products/docker-desktop |

#### Option B — Manual (no Docker)
| Software | Version | Download |
|---|---|---|
| Flutter SDK | 3.22 or later | https://flutter.dev/docs/get-started/install |
| Android Studio | Latest | https://developer.android.com/studio |
| Java JDK | 17 or later | https://adoptium.net |
| Node.js | 18 LTS or later | https://nodejs.org |
| PostgreSQL | 15 or later | https://www.postgresql.org/download |

Also install these VS Code extensions if using VS Code:
- Flutter
- Dart
- REST Client (optional, for API testing)

---

### Step 1 — Copy the Project Files

**Option A: ZIP (easiest)**
1. On your current machine, right-click the `taskguard_ai` folder → Compress / Send to ZIP
2. Copy the ZIP to the new machine via USB drive, Google Drive, or file transfer
3. Extract it to a folder, e.g. `C:\Projects\taskguard_ai` or `~/Projects/taskguard_ai`

**Option B: Git**
```bash
# On current machine — initialise and push to GitHub (private repo)
cd taskguard_ai
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/YOUR_USERNAME/taskguard-ai.git
git push -u origin main

# On new machine
git clone https://github.com/YOUR_USERNAME/taskguard-ai.git
```

> IMPORTANT: The `backend/.env` file contains your API keys and secrets.
> If you use Git, add `.env` to `.gitignore` and transfer the `.env` file separately (USB / secure message).
> Never commit `.env` to a public repository.

---

### Step 2A — Set Up the Backend with Docker (Recommended)

1. Make sure Docker Desktop is running
2. Navigate to the project root:
   ```bash
   cd taskguard_ai
   ```
3. Start everything with one command:
   ```bash
   docker compose up --build
   ```
   Docker will automatically:
   - Start a PostgreSQL database
   - Run all Prisma migrations
   - Start the Node.js server on port 3000

   You should see: `Server running on port 3000`

4. To stop: press `Ctrl+C`, then `docker compose down`
5. To start again next time (no rebuild needed): `docker compose up`

Skip to **Step 4** (Update the Flutter IP address).

---

### Step 2B — Set Up the Database Manually (without Docker)

Open **pgAdmin** or **psql** on the new machine and run:

```sql
-- Create the database user
CREATE USER taskguard WITH PASSWORD '1234Perian';

-- Allow it to create shadow databases (needed by Prisma)
ALTER USER taskguard CREATEDB;

-- Create the database
CREATE DATABASE taskguard_db OWNER taskguard;

-- Connect to the new database
\c taskguard_db

-- Grant permissions
GRANT ALL ON SCHEMA public TO taskguard;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO taskguard;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO taskguard;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO taskguard;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO taskguard;
```

---

### Step 3 — Configure the Backend

1. Navigate into the backend folder:
   ```bash
   cd taskguard_ai/backend
   ```

2. Make sure the `.env` file is present (copy it from the original machine if needed). It should contain:
   ```
   PORT=3000
   NODE_ENV=development
   DATABASE_URL=postgresql://taskguard:1234Perian@localhost:5432/taskguard_db
   JWT_SECRET=<your secret>
   JWT_REFRESH_SECRET=<your secret>
   GOOGLE_CLIENT_ID=<your client id>
   OPENAI_API_KEY=sk-or-v1-<your openrouter key>
   FIREBASE_SERVICE_ACCOUNT=<single-line JSON>
   ```

3. Install Node.js dependencies:
   ```bash
   npm install
   ```

4. Run Prisma migrations (creates all tables):
   ```bash
   npx prisma migrate dev --name init
   ```
   If it asks for a shadow database URL, your user already has CREATEDB so it should work automatically.

5. Generate the Prisma client:
   ```bash
   npx prisma generate
   ```

6. Start the server:
   ```bash
   node server.js
   ```
   You should see: `Server running on port 3000` and `Database connected`.

---

### Step 4 — Update the Flutter App's API URL

The Flutter app needs to know the **IP address of the machine running the backend**.

Open: `lib/services/api_client.dart` — find this section:

```dart
static String get _baseUrl {
  if (kIsWeb) return 'http://localhost:3000/api';
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://192.168.206.77:3000/api'; // <-- CHANGE THIS
  }
  return 'http://localhost:3000/api';
}
```

Find the new machine's IP address:
- **Windows**: open PowerShell → run `ipconfig` → look for "IPv4 Address" under your WiFi adapter
- **Mac/Linux**: run `ifconfig` → look for `inet` under `en0` (WiFi)

Replace `192.168.206.77` with the new machine's IP address.

> The phone and the PC running the backend **must be on the same WiFi network**.

---

### Step 5 — Set Up the Flutter App

1. Navigate to the project root:
   ```bash
   cd taskguard_ai
   ```

2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. Verify Flutter is set up correctly:
   ```bash
   flutter doctor
   ```
   Fix any issues it reports (Android SDK, licenses, etc.).

4. Accept Android licenses if prompted:
   ```bash
   flutter doctor --android-licenses
   ```

5. Connect your Android phone via USB with USB Debugging enabled, OR start an Android emulator.

6. Run the app:
   ```bash
   flutter run
   ```

---

### Step 6 — Windows Firewall (if using a real Android phone)

The phone needs to reach port 3000 on the PC. On the new machine:

1. Open **Windows Defender Firewall with Advanced Security**
2. Click **Inbound Rules** → **New Rule**
3. Select **Port** → **TCP** → enter `3000`
4. Select **Allow the connection**
5. Apply to **Domain, Private, Public**
6. Name it `TaskGuard Backend`

---

### Step 7 — Google Sign-In (Firebase)

The Google Sign-In and Firebase push notifications are tied to the Firebase project `taskguard-ai-bcd9a`. On the new machine:

1. The `backend/.env` already contains the Firebase service account JSON — no changes needed for the backend.

2. For the Flutter app, you need the `google-services.json` file placed at:
   ```
   android/app/google-services.json
   ```
   Download it from [Firebase Console](https://console.firebase.google.com) → Project Settings → Your Apps → Android app → Download `google-services.json`.

3. Add the SHA-1 fingerprint of the new machine's debug keystore to the Firebase app:
   ```bash
   # Windows (adjust JDK path if needed)
   & "C:\Program Files\Java\jdk-25\bin\keytool.exe" -keystore "$env:USERPROFILE\.android\debug.keystore" -list -v -storepass android
   ```
   Copy the SHA-1 value → Firebase Console → Project Settings → Your Android App → Add fingerprint.

---

## 6. Running Everything Together (Daily Use)

Every time you want to run the app:

**Terminal 1 — Backend:**
```bash
cd taskguard_ai/backend
node server.js
```

**Terminal 2 — Flutter (if running from terminal):**
```bash
cd taskguard_ai
flutter run
```

Or just press **Run** in Android Studio / VS Code with a device connected.

---

## 7. Project File Structure

```
taskguard_ai/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── theme/
│   │   ├── app_colors.dart          # Brand colours (pink #E91E8C)
│   │   └── app_theme.dart           # MaterialTheme config
│   ├── services/
│   │   ├── api_client.dart          # Dio HTTP client + token interceptor
│   │   ├── auth_service.dart        # Register, login, Google sign-in, logout
│   │   ├── task_service.dart        # CRUD tasks + offline sync
│   │   ├── ai_service.dart          # Chat, overload check, daily plan
│   │   ├── insights_service.dart    # Productivity score, peak hours
│   │   ├── focus_service.dart       # Focus session start/end
│   │   └── local_storage.dart       # Hive offline cache
│   ├── screens/
│   │   ├── splash/                  # SplashScreen
│   │   ├── onboarding/              # OnboardingScreen
│   │   ├── auth/                    # LoginScreen, RegisterScreen
│   │   ├── home/                    # HomeScreen
│   │   ├── tasks/                   # NewTaskScreen
│   │   ├── chat/                    # ChatScreen
│   │   ├── focus/                   # FocusTimerScreen
│   │   ├── insights/                # InsightsScreen
│   │   ├── calendar/                # CalendarScreen
│   │   └── settings/                # SettingsScreen + sub-screens
│   └── widgets/
│       ├── app_header.dart          # Top app bar
│       ├── bottom_nav_shell.dart    # Bottom navigation
│       └── offline_banner.dart      # Grey offline indicator
│
├── backend/
│   ├── server.js                    # Express app entry
│   ├── .env                         # Secrets (never commit this)
│   ├── package.json
│   ├── prisma/
│   │   └── schema.prisma            # Database schema
│   └── src/
│       ├── config/
│       │   ├── database.js          # Prisma client instance
│       │   └── openai.js            # OpenRouter client
│       ├── middleware/
│       │   ├── auth.js              # JWT verification
│       │   ├── validate.js          # Request validation
│       │   └── errorHandler.js      # Global error handler
│       ├── controllers/             # Business logic per feature
│       └── routes/                  # API route definitions
│
└── android/
    └── app/
        └── google-services.json     # Firebase config (download from Firebase Console)
```

---

## 8. API Keys and Secrets Summary

| Key | Where to Get It | Used For |
|---|---|---|
| `OPENAI_API_KEY` | https://openrouter.ai → Keys | AI chat and overload analysis |
| `GOOGLE_CLIENT_ID` | Google Cloud Console → OAuth 2.0 | Google Sign-In |
| `FIREBASE_SERVICE_ACCOUNT` | Firebase Console → Project Settings → Service Accounts | Push notifications |
| `JWT_SECRET` | Any random 64-char hex string | Signing access tokens |
| `JWT_REFRESH_SECRET` | Any random 64-char hex string | Signing refresh tokens |

All of these are already configured in `backend/.env`. The new machine just needs that file copied over.

---

## 9. Common Problems and Fixes

| Problem | Cause | Fix |
|---|---|---|
| "Offline — showing cached data" on a working network | Backend not running OR wrong IP | Start `node server.js` and check IP in `api_client.dart` |
| "Registration failed" | Backend unreachable or DB error | Check backend terminal for error messages |
| AI chat gets no reply | OpenRouter key wrong or quota exceeded | Check `OPENAI_API_KEY` in `.env`; verify at openrouter.ai |
| `npx prisma migrate` fails with P3014 | DB user lacks CREATEDB | Run `ALTER USER taskguard CREATEDB;` in pgAdmin |
| `Permission denied for schema public` | Missing GRANTs | Run the 5 GRANT commands from Step 2 above |
| Google Sign-In fails on new device | SHA-1 not registered | Add new machine's debug SHA-1 to Firebase Console |
| `flutter run` fails with SDK errors | Flutter not installed or PATH missing | Run `flutter doctor` and follow instructions |
