# Louage Live

Application mobile de **suivi en temps réel et de réservation de places dans les louages** tunisiens.
Le voyageur voit en direct le remplissage du louage en tête de file (ex. 6/8), l'heure de départ estimée,
et peut réserver une place avec un QR code. Le chauffeur, l'agent de station et l'administrateur ont
chacun leur espace.

Projet Tutoré Métier — 3LBC-BIS, Esprit School of Business, 2026/2027.

**Stack :** Flutter (Android + iOS) · Supabase (PostgreSQL, Auth, Realtime) · Riverpod · go_router ·
localisation français / arabe (RTL).

## Prérequis

- Flutter **3.50+** (`flutter --version`) — `brew install --cask flutter`
- Android : Android Studio + SDK, et un téléphone Android (débogage USB activé) ou un émulateur
- iOS (macOS uniquement) : Xcode + CocoaPods (`brew install cocoapods`), un iPhone en mode développeur
- Supabase CLI (pour les migrations) — `brew install supabase/tap/supabase`
- `flutter doctor` doit être vert pour au moins une cible

## Configuration (`config/env.json`)

Les clés Supabase ne sont **jamais** commitées. `config/env.json` est dans `.gitignore`.

```bash
cp config/env.example.json config/env.json
```

Puis remplir avec les valeurs du projet (Supabase Dashboard → Project Settings → API) :

```json
{ "SUPABASE_URL": "https://xxxx.supabase.co", "SUPABASE_ANON_KEY": "clé anon ou publishable" }
```

> ⚠️ Uniquement la clé **publique** (anon / publishable). La clé `service_role` / secrète ne doit
> jamais apparaître dans l'application ni dans le dépôt.

Si le fichier n'est pas fourni ou contient encore les valeurs d'exemple, l'application affiche un
écran d'erreur de configuration.

## Lancer l'application

```bash
flutter pub get
flutter devices                                        # vérifier que le téléphone est détecté
flutter run --dart-define-from-file=config/env.json
```

Dans VS Code, la configuration **« Louage Live (debug) »** (`.vscode/launch.json`) passe déjà ce paramètre.

Premier lancement sur iPhone : ouvrir `ios/Runner.xcworkspace` dans Xcode → *Signing & Capabilities* →
choisir votre équipe (Apple ID gratuit suffit), puis sur l'iPhone : Réglages → Général →
VPN et gestion de l'appareil → faire confiance au profil développeur.

## Vérifications

```bash
flutter analyze
flutter test
```

## Structure

```
lib/
  main.dart, app.dart
  core/       config, supabase, router (redirection par rôle), theme, l10n (langue FR/AR)
  features/   auth, voyageur, chauffeur, agent, admin, file_attente
              chacune avec data/ · logic/ · presentation/
  l10n/       app_fr.arb (modèle), app_ar.arb
supabase/     migrations/, seed.sql
config/       env.example.json (commité), env.json (ignoré)
```

Tous les textes affichés passent par les fichiers ARB (`AppLocalizations.of(context)`) — aucun texte en dur.

## Règles Git

- Ne jamais commiter directement sur `main`.
- Une branche par user story : `US-XX-nom-court` (ex. `US-04-file-temps-reel`).
- Ouvrir une pull request vers `main` avec `Closes #XX` dans la description
  (les numéros d'issues correspondent aux numéros d'US).
- Messages de commit courts, à l'impératif : `Ajoute l'écran de connexion`.

Voir `CLAUDE.md` pour le contexte complet du projet (modèle du domaine, règles non négociables).
