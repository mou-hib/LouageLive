# Louage Live — Project context

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

## Technical notes (learned during setup)

- **Flutter 3.50**: Material and Cupertino moved to the `material_ui` / `cupertino_ui` packages.
  Import `package:material_ui/material_ui.dart`, not `package:flutter/material.dart` (deprecated).
- **Localization delegates**: use `appLocalizationsDelegates` from
  `lib/core/l10n/app_localizations_delegates.dart`, **not** `AppLocalizations.localizationsDelegates`.
  `gen-l10n` still emits the old `flutter_localizations` delegates, which the new Material widgets
  don't find ("No MaterialLocalizations found").
- **Supabase key**: `Supabase.initialize(publishableKey: ...)` (`anonKey` is deprecated). The value
  still comes from `SUPABASE_ANON_KEY` in `config/env.json`; a legacy anon key or a publishable key both work.
- **Run**: `flutter run --dart-define-from-file=config/env.json` (or the VS Code launch config).
  Without real values the app shows a configuration error screen.
- **Test devices**: physical Android phone and physical iPhone (free Apple ID: re-install every 7 days,
  no remote push). No iOS simulator runtime is installed on purpose. The simulator has no camera anyway.
- **Roles**: `AuthRepository.getRole()` reads `profiles.role`; falls back to `voyageur` until US-01
  creates the table. The router (`redirectFor`) only lets a signed-in user reach their own role home.
