# AvesQuest

AvesQuest is a mobile bird identification and collection journal. Snap a photo of a bird, let AI identify it, and build your personal BirdDex collection.

Built with Flutter & Provider, powered by Cloudflare Workers AI (Llama 4 Scout Vision).

## Features

- **AI Bird Identification** — Take or upload a photo; the app compresses it locally and sends it to Cloudflare Workers AI (Llama 4 Scout 17B) for species identification
- **Personal Collection** — Every identified bird is saved to your local BirdDex with name, scientific name, rarity tier, habitat, diet, and fun facts
- **Rarity System** — Each species gets a rarity tier (Common / Uncommon / Rare / Legendary) computed from IUCN conservation status and geographic range data (10,981 species)
- **Pending Queue** — Photos queue for identification; retry failed ones, delete unwanted ones
- **Search & Filter** — Filter your collection by rarity tier or search by name, species, or habitat
- **Stats & Achievements** — Overview stats (streak, first catch, habitats) with unlockable achievements
- **Offline-Friendly** — The app works offline; identification requires an internet connection
- **Photo EXIF Handling** — Correctly reads EXIF orientation metadata on all platforms via `exif_reader`
- **Forest Expedition Theme** — Warm, tactile, nature-inspired design system

## Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter 3.x (Dart ^3.9.2) |
| **State Management** | Provider (`ChangeNotifier`) |
| **Database** | SQLite via `sqflite` |
| **AI Backend** | Cloudflare Workers AI (`@cf/meta/llama-4-scout-17b-16e-instruct`) |
| **Camera / Gallery** | `image_picker` |
| **EXIF Metadata** | `exif_reader` |
| **Fonts** | Google Fonts (Plus Jakarta Sans) |
| **Icons** | Material Icons |

## Architecture

```
lib/
├── data/
│   └── rarity_table.dart      # Static data (10,981 species rarity mapping)
├── models/
│   ├── achievement.dart       # Achievement definitions and unlock logic
│   ├── bird.dart              # Bird entity (name, species, rarity, habitat, diet, etc.)
│   ├── identification_result.dart  # AI identification result model
│   ├── pending_queue_item.dart     # Queued identification item
│   ├── quest.dart             # Quest definitions and progress
│   └── rarity.dart            # Rarity enum and tier logic
├── providers/
│   ├── bird_provider.dart     # Bird CRUD and state
│   ├── identification_provider.dart  # AI identification orchestration
│   ├── pending_queue_provider.dart    # Queue state management
│   └── quest_provider.dart    # Quest progression and XP
├── repositories/
│   └── bird_repository.dart   # SQLite data access layer
├── screens/
│   ├── app_shell.dart         # Bottom-nav host (JournalHome / Journal / Profile)
│   ├── bird_detail_screen.dart # Single bird detail view
│   ├── capture_screen.dart    # Camera / gallery capture flow
│   ├── journal_home_screen.dart # Dashboard: identity card, quest ring, recent discoveries
│   ├── journal_screen.dart    # Full collection grid + pending queue tabs
│   ├── profile_screen.dart    # Overview, achievements, quests tabs
│   └── splash_screen.dart     # Entry screen with brand assets
├── services/
│   ├── ai_service.dart        # Cloudflare Workers AI communication with local image compression
│   ├── auto_sync_service.dart # Background queue processing
│   └── photo_service.dart     # Photo storage and EXIF handling
├── theme/
│   ├── app_colors.dart        # Color tokens
│   ├── app_radius_extension.dart
│   ├── app_spacing.dart       # Spacing scale
│   ├── app_theme.dart         # Material theme configuration
│   └── app_typography.dart    # Typography scale
├── widgets/
│   ├── avesquest_bottom_nav.dart   # Bottom navigation bar
│   ├── avesquest_header.dart       # Reusable header widget
│   ├── bird_grid_card.dart         # Bird card for collection grid
│   ├── discovery_progress_ring.dart # Quest progress ring
│   ├── game_background.dart        # Decorative background layer
│   ├── journey_stats_strip.dart    # Stats summary strip
│   ├── offline_banner.dart         # Offline connectivity banner
│   ├── oriented_image.dart         # EXIF-aware image display
│   ├── rarity_badge.dart           # Rarity badge widget
│   ├── recent_discovery_card.dart  # Recent catch card for dashboard
│   ├── route_transitions.dart      # Custom page transitions
│   └── streak_tracker.dart         # Streak display widget
└── main.dart

server/
├── scripts/
│   └── generate_rarity_table.py  # Builds rarity_table.dart from IUCN data
└── src/
    ├── worker.js      # Cloudflare Worker — AI inference via Workers AI binding
    └── prompt.js      # AI prompt for bird identification
```

## Screens

| Screen | Purpose | Main Widgets | User Actions |
|---|---|---|---|
| **SplashScreen** | Entry point; displays brand logo, mascot, and animated floating leaves on a full-bleed background | Background image, gradient overlay, `AnimationController` (5 floating leaves), logo, mascot, "START ADVENTURE" button | Tap **START ADVENTURE** → navigates to `AppShell` |
| **AppShell** | Main app host with bottom navigation and animated tab switching | `Scaffold`, `AnimatedSwitcher` (fade+scale transition), `AvesQuestBottomNav`, tab bodies (`JournalHomeScreen`, `JournalScreen`, `ProfileScreen`) | Tap tab icons to switch sections; tap center camera FAB to open `CaptureScreen`; after capture, auto-switches to Journal tab and highlights the new bird |
| **JournalHomeScreen** | Dashboard showing birder identity card, quest progress ring, recent discoveries feed, streak tracker, and journey stats | `_HomeIdentityCard` (tier avatar, level pill, XP progress bar with milestone dots), `_HomeQuestCard` (`DiscoveryProgressRing` + tips), `StreakTracker`, `RecentDiscoveryCard` (×2), `JourneyStatsStrip` | Pull-to-refresh reloads data; tap a recent discovery card → navigates to `BirdDetailScreen` |
| **JournalScreen** | Full browsable collection with spiral notebook metaphor; two tabs: Collection (searchable/filterable grid) and Pending (identification queue) | `_SpiralBinding` (CustomPaint), `_JournalHeader` with tab toggle, `TabBarView`, search bar, rarity filter chips, `GridView` of `BirdGridCard`, `_QueueCard` list with retry/delete | Search by name/species/habitat; tap rarity chips to filter; tap bird card → `BirdDetailScreen`; retry or delete pending queue items |
| **CaptureScreen** | Camera/gallery photo capture flow for AI identification | `OfflineBanner`, source picker (camera/gallery buttons), image preview with EXIF handling, "Retake" / "Use This Photo" buttons, loading spinner | Tap **Take a Photo** or **Upload from Gallery** → preview → **Use This Photo** to queue for identification; on success returns `bird.id` to `AppShell` |
| **BirdDetailScreen** | Full detail view for a single identified bird with identity, stats, species info, fun facts, and actions | `_DetailTopBar` (back, rarity badge pill, card index, share), `_DetailPhotoCard` (spiral binding, rarity-colored border/glow), `_DetailIdentity`, `_DetailStats` (habitat, diet, length, weight, range, confidence), `_SpeciesInfoCard`, `_FunFactsSection`, `_ReidentifyButton`, `_DeleteButton`, `_CaughtDate` | Back; share via system share sheet; re-identify with AI; delete with confirmation dialog |
| **ProfileScreen** | Player profile hub with three tabs: Overview (identity + stats), Achievements (unlocked/locked list), Quests (daily/weekly/seasonal claims) | `_ProfileTabBar` (segmented toggle), `_ProfileIdentityCard` (tier, XP bar), `_ProfileStatsBlock` (collected, habitats, streak, rarity breakdown), `_AchievementCard` list, `_QuestTabToggle`, `_QuestRow` | Switch tabs; claim individual quests or "Claim All"; view achievement unlock progress |

## Getting Started

### Prerequisites

- Flutter SDK (compatible with Dart ^3.9.2)
- A Cloudflare account with Workers AI enabled
- (Optional) Node.js + `npx` for deploying the proxy worker

### Running the App

```bash
cd birddex
flutter pub get
flutter run
```

The app defaults to pointing at the deployed proxy at `https://birddex-proxy.birddex.workers.dev`. To use a different proxy URL:

```bash
flutter run --dart-define=BIRDDEX_PROXY_URL=http://localhost:8787
```

### Setting Up the AI Proxy Server

The app identifies birds by sending compressed photos to a Cloudflare Worker that runs inference via Workers AI.

1. **Install dependencies & deploy:**

   ```bash
   cd server
   npm install
   npx wrangler deploy -c wrangler.toml
   ```

2. **Accept the model license (one-time):**

   For Llama models on Cloudflare Workers AI, you must accept the license via the API:

   ```bash
   curl https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/ai/run/@cf/meta/llama-4-scout-17b-16e-instruct \
     -X POST \
     -H "Authorization: Bearer $CLOUDFLARE_AUTH_TOKEN" \
     -d '{ "prompt": "agree"}'
   ```

   Or accept it manually in the [Cloudflare Dashboard](https://dash.cloudflare.com) → Workers AI → Models.

3. **Update the default URL** in `lib/providers/identification_provider.dart` if you're using a custom worker domain.

### Running the Proxy Locally

```bash
cd server
npm install
npx wrangler dev -c wrangler.toml
```

Then run the Flutter app with:

```bash
flutter run --dart-define=BIRDDEX_PROXY_URL=http://localhost:8787
```

### Generating the Rarity Table

The rarity table (`lib/data/rarity_table.dart`) is generated from IUCN Red List data. To regenerate:

```bash
cd server/scripts
pip install -r requirements.txt  # pandas
python generate_rarity_table.py
```

This reads `assessments.csv` from the IUCN Red List and produces a Dart file with 10,981 species mapped to rarity tiers.

## Rarity System

Rarity is determined entirely by the app using two signals from the IUCN Red List:

1. **IUCN Category** — Extinct, Critically Endangered, Endangered, Vulnerable, Near Threatened, Least Concern, Data Deficient
2. **Realm Count** — Number of geographic realms a species inhabits (wider range = more common)

Thresholds: `[25, 50, 72]` produce approximately:

| Tier | Distribution |
|---|---|
| Common | 2 species |
| Uncommon | ~27% |
| Rare | ~68% |
| Legendary | ~5% |

The AI model never determines rarity — it only provides the species name.

## Design System

BirdDex uses the **Forest Expedition** design language — warm, tactile, and nature-inspired.

- **Colors:** Deep forest green (primary), earthy wood brown (secondary), vibrant leaf green (tertiary), sunny yellow (accent), parchment (background)
- **Typography:** Plus Jakarta Sans — heavy weights for headlines, medium for body, bold all-caps for labels
- **Shapes:** Pill-shaped and organic — no sharp corners
- **Depth:** Inset shadows and tonal layers instead of drop shadows
- **Spacing:** 8px base unit with generous margins (20px on mobile)

See `birddex_ui_design/forest_expedition/DESIGN.md` for the full design spec.

## Configuration

| Environment Variable / Dart Define | Purpose | Default |
|---|---|---|
| `BIRDDEX_PROXY_URL` | URL of the Cloudflare Worker proxy | `https://birddex-proxy.birddex.workers.dev` |
| `GEMINI_API_KEY` / `HF_API_KEY` (server secret) | Previously used AI provider keys; not needed for Workers AI | — |

## Project Structure

```
birddex/
├── android/
├── ios/
├── lib/
│   ├── data/
│   │   └── rarity_table.dart      # 10,981 species rarity data
│   ├── models/
│   │   ├── achievement.dart
│   │   ├── bird.dart
│   │   ├── identification_result.dart
│   │   ├── pending_queue_item.dart
│   │   ├── quest.dart
│   │   └── rarity.dart
│   ├── providers/
│   │   ├── bird_provider.dart
│   │   ├── identification_provider.dart
│   │   ├── pending_queue_provider.dart
│   │   └── quest_provider.dart
│   ├── repositories/
│   │   └── bird_repository.dart
│   ├── screens/
│   │   ├── app_shell.dart
│   │   ├── bird_detail_screen.dart
│   │   ├── capture_screen.dart
│   │   ├── journal_home_screen.dart
│   │   ├── journal_screen.dart
│   │   ├── profile_screen.dart
│   │   └── splash_screen.dart
│   ├── services/
│   │   ├── ai_service.dart
│   │   ├── auto_sync_service.dart
│   │   └── photo_service.dart
│   ├── theme/
│   │   ├── app_colors.dart
│   │   ├── app_radius_extension.dart
│   │   ├── app_spacing.dart
│   │   ├── app_theme.dart
│   │   └── app_typography.dart
│   ├── widgets/
│   │   ├── avesquest_bottom_nav.dart
│   │   ├── avesquest_header.dart
│   │   ├── bird_grid_card.dart
│   │   ├── discovery_progress_ring.dart
│   │   ├── game_background.dart
│   │   ├── journey_stats_strip.dart
│   │   ├── offline_banner.dart
│   │   ├── oriented_image.dart
│   │   ├── rarity_badge.dart
│   │   ├── recent_discovery_card.dart
│   │   ├── route_transitions.dart
│   │   └── streak_tracker.dart
│   └── main.dart
├── server/
│   ├── scripts/
│   │   └── generate_rarity_table.py
│   └── src/
│       ├── worker.js      # Cloudflare Worker — AI inference via Workers AI binding
│       └── prompt.js
├── birddex_ui_design/
│   └── forest_expedition/
│       └── DESIGN.md
└── pubspec.yaml
```

## License

MIT
