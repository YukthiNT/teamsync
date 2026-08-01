# TeamSync — Real-Time Collaborative Workspace

A Flutter app with a live team chat and a synced Kanban task board, built to
demonstrate real-time state management using Supabase (Postgres + Auth +
Realtime) — no credit card required to run it.

## What it demonstrates

- **Real-time backend sync** — Supabase's `.stream()` subscribes to
  Postgres changes over a websocket, pushing updates to every connected
  device instantly (`SupabaseService.messageStream()`, `taskStream()`,
  `presenceStream()`).
- **Optimistic UI** — when you send a chat message, it appears instantly
  with a spinner, before the server confirms it. See `ChatController` in
  `lib/providers/app_providers.dart` — this is the single most
  interview-worthy piece of code in the project.
- **Presence indicators** — online/offline dots that update automatically
  when the app is backgrounded or foregrounded, via
  `WidgetsBindingObserver` in `SupabaseService`.
- **State management with Riverpod** — `StreamProvider` for live data,
  `StateNotifierProvider` for the optimistic chat state.
- **Row Level Security** — Postgres policies (in `supabase_setup.sql`)
  control exactly who can read/write each table, done properly instead
  of leaving the database wide open.

## Project structure

```
lib/
  models/          ChatMessage, TaskItem, UserPresence
  services/         SupabaseService — all database/Auth calls live here
  providers/         Riverpod providers, incl. optimistic ChatController
  screens/          SignIn, Home (tab shell), Chat, TaskBoard
  main.dart          App entry + Supabase init
supabase_setup.sql   Run this once in Supabase's SQL Editor
```

## Setup (do this before it will run)

You need a free Supabase project — no card required, takes about 5 minutes.

### 1. Install dependencies
```bash
flutter pub get
```

### 2. Create your Supabase project
- Go to https://supabase.com/dashboard → sign up / log in (GitHub or
  email).
- Click **New project**.
- Give it a name (e.g. `teamsync`), set a database password (save it
  somewhere, you likely won't need it again), pick a region close to
  you → **Create new project**. Wait ~1-2 minutes for it to provision.

### 3. Run the database setup script
- In the left sidebar, click **SQL Editor** → **New query**.
- Open `supabase_setup.sql` from this project, copy its entire contents,
  paste into the SQL editor.
- Click **Run** (or press Ctrl+Enter). You should see "Success. No rows
  returned."
- This creates the `messages`, `presence`, and `tasks` tables, sets up
  security policies, and turns on realtime for all three.

### 4. Enable anonymous sign-ins
- In the left sidebar, click **Authentication → Sign In / Providers**.
- Find **Anonymous Sign-Ins** and toggle it **on**. Save if prompted.

### 5. Get your API keys
- In the left sidebar, click **Project Settings → Data API** (or
  **Settings → API** depending on the dashboard version).
- Copy the **Project URL**.
- Copy the **anon / public** key (NOT the `service_role` key — that one
  must stay secret and never goes in client code).

### 6. Paste your keys into the app
Open `lib/main.dart` and replace these two lines with your real values:
```dart
const String supabaseUrl = 'YOUR_SUPABASE_PROJECT_URL';
const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

### 7. Run it
```bash
flutter run
```
Run it on two devices/emulators (or two browser tabs) and watch
messages, presence, and tasks sync live between them — that's the demo
worth showing in your application or interview.

## Important: free projects auto-pause

Supabase pauses free projects after 7 days of no activity. If your app
suddenly can't connect, log into https://supabase.com/dashboard and
click **Restore/Resume project** — takes under a minute. Worth doing
right before a demo or interview just in case.

## Talking points for your application

- "I built optimistic UI so messages feel instant instead of waiting on
  a round trip — the local bubble shows a spinner and Supabase's
  realtime stream reconciles it once confirmed, or flags it as failed
  if the write throws."
- "Presence is handled with `WidgetsBindingObserver` so a user's status
  flips to offline the moment they background the app, not just on
  explicit sign-out."
- "I used Postgres Row Level Security policies instead of leaving the
  database open, so each user can only write their own presence row and
  messages under their own ID."
- "State is split between `StreamProvider`s for server-driven data and a
  `StateNotifierProvider` for the chat list, since chat needs to merge
  server state with pending local writes."

## Extending it further (good next steps to mention you're planning)

- Typing indicators (write an `is_typing` column to presence, debounce
  client-side).
- Push notifications when the app is backgrounded.
- Drag-and-drop task cards instead of tap-to-advance.
- Message reactions / threads.
