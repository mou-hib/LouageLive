# Louage Live — Project environment setup (instructions for Claude Code)

You are setting up the development environment and the empty project skeleton for **Louage Live**.
Read this whole file before doing anything. Work step by step, and stop to ask me when a step
needs a decision or a secret that this file does not give you.

---

## Part A — Project context

Copy this whole Part A into a `CLAUDE.md` file at the repository root (step 7). It is the permanent
context for every later session.

### What the app is
Louage Live is a mobile app for **real-time tracking and seat booking in Tunisian louages**
(shared intercity taxis). It is a student project: "Projet Tutoré Métier", class 3LBC-BIS,
Esprit School of Business, 2026/2027. Five students; Mouhib Mejri is the Scrum Master.

How a louage station works:
- Each line (e.g. Tunis → Sousse) has its own FIFO queue of louages.
- Only the louage at the head of the queue fills; the others wait.
- A louage leaves when its **8 seats** are full. There is no timetable.

Louage lifecycle in a queue: `EN_ATTENTE → EN_REMPLISSAGE → COMPLET → PARTI`.
When a louage leaves (`PARTI`), the next one in the line becomes `EN_REMPLISSAGE` automatically.

### Actors and roles
| Role | Code | Main actions |
|---|---|---|
| Voyageur | `voyageur` | Search a trip, see live seats (e.g. 6/8), see estimated departure, book a seat (QR code), cancel, notifications, history |
| Chauffeur | `chauffeur` | Join a queue by scanning the station QR code, +1 / −1 passenger, scan a booking QR code, see position in queue |
| Agent de station | `agent` | Supervises ONE line: correct seat count, remove a louage, act for a driver without a smartphone |
| Administrateur | `admin` | Manage stations, lines, official fares, accounts; dashboard |

### Domain model (keep these names)
- `Utilisateur` (abstract) → `Voyageur`, `Chauffeur`, `AgentStation`, `Administrateur`
- `Station` 1—* `Ligne` (villeDepart, villeArrivee, tarifOfficiel)
- `Louage` = the physical vehicle (immatriculation, capacite = 8), driven by one Chauffeur
- `Passage` = one stay of a louage in a line's queue (etat, placesOccupees, rang, heureEntree, heureDepart).
  **Louage and Passage are separate on purpose** — this is what makes history and statistics possible.
- `Reservation` (codeQR, etat: EN_ATTENTE / CONFIRMEE / ANNULEE / EXPIREE, dateCreation, dateExpiration) → linked to a Passage and a Voyageur
- `Notification`

### Tech stack
- **Flutter** (Dart), one codebase for Android + iOS. A Flutter Web build for the admin/agent
  dashboard may come later (not confirmed yet — do not build it now).
- **Supabase**: PostgreSQL, Auth, Realtime. Hosted project (not local Docker) unless I say otherwise.
- State management: **Riverpod** (`flutter_riverpod`). Navigation: **go_router**.
- Localization: Flutter `gen-l10n` with ARB files, **French (default) and Arabic** (right-to-left).
- QR: `mobile_scanner` (scan) and `qr_flutter` (display).

### Non-negotiable rules
1. **Never change a seat count from the app with a direct table UPDATE.** Seat changes
   (+1, −1, booking, cancel, expiry) will go through Postgres functions called with RPC, so the
   database can guarantee **never more than 8 seats**, even with simultaneous actions (BNF-2).
2. **No hard-coded user-facing text.** Every string goes through the ARB files
   (`AppLocalizations.of(context)`), so the Arabic version (US-22) does not need screen rewrites.
   Use direction-aware layout (`EdgeInsetsDirectional`, `AlignmentDirectional`, `start`/`end`, not `left`/`right`).
3. **Access depends on the role** (BNF-6). The real protection is Row Level Security in Supabase;
   the app only hides what a role should not see.
4. **No secrets in Git.** The Supabase URL and the public (anon / publishable) key go in
   `config/env.json`, which is git-ignored. The **service_role / secret key must never appear in
   the app or the repo.**
5. Driver screens: very simple, big buttons usable with one hand (BNF-4). Must stay usable on 3G (BNF-3).
6. Code organised by feature, each with `data/`, `logic/`, `presentation/` layers (BNF-9).

### Conventions
- Code identifiers in English or French are both fine, but **domain names stay as in the model
  above** (`Passage`, `Louage`, `Ligne`, `Reservation`, …).
- User-facing text: French and Arabic only, through ARB files.
- Git: never commit directly to `main`. One branch per user story: `US-XX-short-name`
  (e.g. `US-04-file-temps-reel`). Open a pull request and put `Closes #XX` in the description
  (issue numbers match US numbers in the GitHub repo `mou-hib/LouageLive`).
- Commit messages in French or English, short, imperative: `Ajoute l'écran de connexion`.

### Backlog reference (GitHub Projects)
Sprint 1 (16/11–22/11, 31 pts): US-01 auth · US-02 join queue by QR · US-03 +1/−1 passenger ·
US-04 live queue · US-05 automatic queue management · US-06 position in queue.
Sprint 2 (23/11–29/11): search, stations, lines & fares, booking + QR, cancel, scan, expiry, agent supervision, remove louage.
Sprint 3 (30/11–06/12): agent for driver without phone, accounts, ETA, notifications, history, dashboard, FR/AR.

---

## Part B — Setup task (do this now)

Goal: a clean Flutter project that runs on a simulator, connects to Supabase, has French/Arabic
working, role-based routing in place, and empty screens for each role. **No business features yet.**

### Step 1 — Check the machine (macOS)
Run and report the results to me before continuing:
- `flutter --version` and `flutter doctor -v`
- `git --version`, `gh --version` (GitHub CLI)
- `supabase --version` (Supabase CLI)

If something is missing, tell me the exact install command and wait for my OK before installing
(Homebrew is fine: e.g. `brew install --cask flutter`, `brew install supabase/tap/supabase`, `brew install gh`).
For iOS: Xcode + CocoaPods. For Android: Android Studio + an emulator. I need at least one working
target; tell me which ones `flutter doctor` says are ready.

### Step 2 — Repository
- If the repo is not cloned yet: `gh repo clone mou-hib/LouageLive` and `cd` into it.
- Create a branch: `git checkout -b setup/environnement`.
- If the repo already contains files, show me what is there before adding anything.

### Step 3 — Create the Flutter project in the repo root
- `flutter create --org tn.louagelive --project-name louage_live --platforms android,ios .`
- Add packages with `flutter pub add` (let pub pick compatible latest versions):
  `supabase_flutter flutter_riverpod go_router intl mobile_scanner qr_flutter shared_preferences`
- Add `flutter_localizations` from the SDK, and set `generate: true` under `flutter:` in `pubspec.yaml`.
- Dev: keep `flutter_lints` (default).

### Step 4 — Folder structure
Create this structure (empty files where there is nothing to put yet; no business logic):

```
lib/
  main.dart                     # init Supabase, ProviderScope, runApp
  app.dart                      # MaterialApp.router, theme, localization, locale provider
  core/
    config/env.dart             # reads SUPABASE_URL / SUPABASE_ANON_KEY from --dart-define
    supabase/supabase_client.dart
    router/app_router.dart      # go_router + redirect by auth state and role
    theme/app_theme.dart        # Material 3, large touch targets
    l10n/locale_provider.dart   # current locale (fr default), saved with shared_preferences
  features/
    auth/{data,logic,presentation}/
    voyageur/{data,logic,presentation}/
    chauffeur/{data,logic,presentation}/
    agent/{data,logic,presentation}/
    admin/{data,logic,presentation}/
    file_attente/{data,logic,presentation}/   # queue + live seats, shared by several roles
  l10n/
    app_fr.arb
    app_ar.arb
l10n.yaml
config/
  env.example.json              # committed, with placeholder values
  env.json                      # git-ignored, real values (I will fill them)
supabase/
  migrations/                   # empty for now — I will add the SQL myself later
  seed.sql                      # empty for now
```

### Step 5 — Configuration and Supabase connection
- `config/env.example.json`:
  ```json
  { "SUPABASE_URL": "https://YOUR-PROJECT.supabase.co", "SUPABASE_ANON_KEY": "YOUR-PUBLIC-ANON-OR-PUBLISHABLE-KEY" }
  ```
- Add `config/env.json` to `.gitignore`. Copy the example to `config/env.json` and **ask me for the
  real URL and public key** (Supabase Dashboard → Project Settings → API). Never ask for the service_role key.
- The app is run with `flutter run --dart-define-from-file=config/env.json`.
  Add a VS Code launch configuration (`.vscode/launch.json`) that passes this flag.
- `main.dart` calls `Supabase.initialize(url: ..., anonKey: ...)` with values from `env.dart`,
  and shows a clear error screen if they are empty.
- **Do not create any tables, policies or functions in Supabase.** The database SQL comes later.
  If I give you the Supabase project ref, you may run `supabase init` and `supabase link` so the
  `supabase/` folder is ready for migrations, but do not push anything.

### Step 6 — Localization, routing and placeholder screens
- `l10n.yaml`: arb dir `lib/l10n`, template `app_fr.arb`, output class `AppLocalizations`.
- Put at least these keys in both ARB files (French and Arabic): app title, login, logout,
  email, password, "Se connecter", the four role home titles, "Changer de langue", a generic error message.
- `app.dart`: `supportedLocales` fr + ar, localization delegates, locale from `locale_provider`.
  Arabic must switch the whole UI to right-to-left automatically.
- Screens (simple placeholders, all text from ARB):
  - `LoginScreen` (email + password fields, button; calls `supabase.auth.signInWithPassword`)
  - `VoyageurHomeScreen`, `ChauffeurHomeScreen`, `AgentHomeScreen`, `AdminHomeScreen`
    (title + logout button + language switch)
- `app_router.dart`:
  - Not signed in → `/login`.
  - Signed in → read the user's role through an `AuthRepository.getRole()` method and redirect to
    `/voyageur`, `/chauffeur`, `/agent` or `/admin`.
  - The `profiles` table does not exist yet. Implement `getRole()` to query
    `profiles.role` for `auth.uid()`, but if the query fails, fall back to `voyageur` and log a
    warning. Leave a `// TODO(US-01)` comment there.
  - Listen to `onAuthStateChange` so login/logout redirects immediately.
- Camera permission for QR scanning: add the iOS `NSCameraUsageDescription` (in French) and the
  Android settings required by the `mobile_scanner` README (check the package docs for the current
  minimum SDK). Do not build the scanner screen yet.

### Step 7 — Project files
- Create `CLAUDE.md` with the full content of **Part A** above.
- Update `README.md`: short description, prerequisites, how to create `config/env.json`, how to run
  (`flutter run --dart-define-from-file=config/env.json`), and the branch / PR rules.
- `.gitignore`: Flutter defaults + `config/env.json` + `.env*` + `supabase/.temp/`.

### Step 8 — Verify
All of these must pass. Show me the output:
1. `flutter analyze` → no errors.
2. `flutter test` → the default test passes (update or replace the counter test so it matches the new app).
3. `flutter run --dart-define-from-file=config/env.json` on a simulator/emulator →
   the login screen appears in French; switching to Arabic flips the layout to right-to-left.
4. `git status` shows **no** `config/env.json` and no key anywhere:
   run `git grep -n "eyJ\|sb_secret\|service_role"` and confirm it returns nothing.

### Step 9 — Commit and pull request
- Commit on `setup/environnement` with a clear message (e.g. `Initialise le projet Flutter et l'environnement`).
- Push and open a pull request to `main` with `gh pr create`. Title:
  `Sprint 0 — Mise en place de l'environnement`. In the description, list what was set up and
  how to run the project.
- **Do not merge.** I will review and merge it myself.

### Out of scope for this task
- No database tables, RLS policies, SQL functions or seed data.
- No business features (no queue, no booking, no scanner screen).
- No web dashboard.
- Do not upgrade the Flutter SDK or change global machine settings without asking.

When you finish, give me a short summary: what was created, the commands to run the app, and
anything that still needs my action (e.g. filling `config/env.json`).
