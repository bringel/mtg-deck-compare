# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture

This is a full-stack Magic: The Gathering deck comparison application with a Ruby/Sinatra backend and Vue 3/TypeScript frontend.

**Backend (Ruby/Sinatra)**:
- `server/api_app.rb` - Main API application with endpoints for deck loading and comparison
- `server/static_app.rb` - Serves the frontend SPA, handles all routes with index.html
- `config.ru` - Rack configuration mapping `/api` to ApiApp and `/` to StaticApp
- Cache: Redis used for caching card and deck data (no persistent database)
- Service Registry pattern for managing shared services (Redis connections)
- Middleware:
  - Case conversion (camelCase ↔ snake_case) between frontend/backend
  - Rate limiting for Scryfall API calls using Redis
- Decklist parsers in `server/decklist_parsers/` for different MTG deck hosting sites
- Fetchers in `server/fetchers/` own all outbound HTTP for deck sources (timeouts, retries, block detection, optional scraping API fallback)
- `server/lib/deck_comparer.rb` - Core logic for comparing multiple decks

**Frontend (Vue 3/TypeScript)**:
- Located in `web/` directory with Vite build system
- API proxy configured in `vite.config.ts` to proxy `/api` to `http://localhost:9292`
- Builds to `public/` directory which is served by StaticApp
- Uses Tailwind CSS for styling

## Development Commands

**Backend (Ruby)**:
```bash
# Install dependencies
bundle install

# Start the backend server (port 9292)
bundle exec rackup -p 9292

# Run the backend tests (minitest, no network or Redis needed)
bundle exec rake test

# Record a real response as a parser fixture
bundle exec rake 'fixtures:record[aetherhub,https://aetherhub.com/Deck/...,deck.html]'
```

**Frontend (Vue/TypeScript)**:
```bash
# Install dependencies
npm install

# Start development server with hot reload
npm run dev

# Type checking
npm run type-check

# Linting (note: the npm script passes --ext, which flat-config ESLint rejects;
# `npx eslint <files>` works)
npm run lint

# Production build
npm run build
```

**Cache**:
- Redis used for caching card and deck data
- No persistent database - data is cached temporarily for performance

## Supported Decklist Sites

The application can parse and import decklists from:
- **Moxfield** (moxfield.com)
- **Archidekt** (archidekt.com)
- **Aetherhub** (aetherhub.com)
- **Deckstats** (deckstats.net)
- **MTGGoldfish** (mtggoldfish.com)
- **MTGDecks** (mtgdecks.net)
- **Manual entry** - users can paste a decklist directly via the UI (stored in Redis with 30-day TTL)

Each parser handles site-specific deck formats and normalizes them into a common structure. Manual decks use a `mtg-deck-compare://manualDeck/<uuid>` URL scheme to identify them in the comparison flow.

`TextListParser` (`server/decklist_parsers/text_list_parser.rb`) handles parsing raw card list text in multiple formats (quantity-first, quantity-last, or with set code and collector number). It recognizes whole-line `Commander`, `Companion`, `Sideboard`, and `Deck` section headers (optionally with a colon or count), and can treat a blank line as the start of the sideboard (`blank_line_starts_sideboard:`) for header-less exports.

### How deck loading works

1. `DeckService#load_from_url` normalizes the URL (`DeckUrl.normalize`), handles manual deck URLs itself, and picks a parser via `ParserList.get_parser!`.
2. Decks are cached under `decks:<url>` for 1 hour, plus a last-known-good copy under `decks:stale:<url>` for 30 days that is served if a refetch fails (except when the deck was deleted).
3. Each parser (`DecklistParser` subclass) implements `parse` → `Models::ParsedDeck`, doing all network access through `fetcher.get(url, params:, accept: :html|:json|:text)`. Parsers never touch timeouts or retries, and tests pass a fake fetcher that serves fixtures from `test/fixtures/`.
4. `Fetchers::HttpFetcher` raises typed errors from `server/decklist_parsers/errors.rb` (`SourceBlockedError`, `SourceUnavailableError`, `DeckNotFoundError`, ...). `DeckService` wraps anything else a parser raises in `ExtractionError`. `ApiApp` renders these as `{error: {code, message, sourceType, fallbackUrl}}`, and the Compare page uses them to explain the failure and link to `fallbackUrl` for manual entry.
5. Commanders are folded into the main deck (`ParsedDeck.from_sections`).

MTGGoldfish needs no browser: deck and archetype pages have the list in `input#deck_input_deck`. For `/deck/<id>` URLs, the parser falls back to the plain-text `/deck/download/<id>` export if the page is blocked.

**Scraping API fallback (optional)**: set `SCRAPING_API_URL` to a vendor URL template containing `{url}` (e.g. `https://app.scrapingbee.com/api/v1/?api_key=KEY&url={url}`) and `SCRAPING_API_SOURCES` to a comma-separated list of source types (e.g. `mtggoldfish,aetherhub`). Those sources then try a direct request first and retry through the API only when blocked.

## API Endpoints

- `GET /api/load_deck?url=<deck_url>` - Load full deck data (URL must be query-encoded); failures return `{error: {code, message, sourceType, fallbackUrl}}`
- `POST /api/create_manual_deck` - Save a manually entered decklist; returns `{deckId, deck}`
- `POST /api/compare_decks` - Compare multiple decks (expects `{deckListUrls: [...]}`)
- `GET /api/check_card/:set/:number` - Get card data from Scryfall
- `POST /api/check_cards` - Batch fetch card data

## Project Structure

- `/server/` - Ruby backend code
  - `/api_app.rb` - Main API endpoints
  - `/models/` - Data models (Card, Deck, CardKey, ParsedDeck)
  - `/services/` - External service integrations
    - `scryfall_service.rb` - Scryfall API with rate limiting
    - `cards_service.rb` - Card fetching/caching
    - `deck_service.rb` - Loads decks from URLs (cache, stale fallback, error wrapping) and saves manual decks
  - `/decklist_parsers/` - Site-specific parsers for different MTG deck sites
    - `errors.rb` - Typed deck loading errors with HTTP status and error code
    - `text_list_parser.rb` - Parses raw card list text (used by manual entry, MTGDecks, and MTGGoldfish)
  - `/fetchers/` - `HttpFetcher`, `BlockDetector`, `ScrapingApiFetcher`, `TieredFetcher`, and the `Fetchers.for` factory
  - `/lib/` - Core business logic (DeckComparer, ServiceRegistry, DeckUrl, AppLogger)
  - `/middleware/` - Rack middleware (rate limiting, case conversion)
- `/web/` - Vue 3 frontend
  - `/src/components/` - Vue components (includes `ManualDeckModal.vue` for manual deck entry)
  - `/src/composables/` - Vue composables (`useTheme.ts` for dark/light/auto mode)
  - `/src/store/` - Pinia stores (`deckStore.ts`, `deckComparisonStore.ts`)
  - `/src/router/` - Vue Router (routes: `/` Home, `/compare` Compare)
  - `/src/lib/` - Frontend utilities (`bingo.ts` fetch wrapper, `cardTypeSorter.ts`, `deckColors.ts`, `queryStringDeckURLs.ts`)
  - `/src/types/` - TypeScript type definitions
- `/test/` - Minitest suite (`test_helper.rb` provides `FakeRedis` and `FakeFetcher`), with recorded site responses in `/test/fixtures/`
- `/public/` - Built frontend assets (generated)
- `config.ru` - Rack application configuration

## Key Features

The application allows users to:
1. Input multiple MTG decklist URLs from supported sites
2. Manually enter a decklist via a modal (saved to Redis for 30 days, referenced by UUID)
3. Parse and load deck data using site-specific parsers
4. Fetch card images and metadata from Scryfall API (with rate limiting)
5. Compare decks to find:
   - Cards common to all decks
   - Cards appearing in multiple (but not all) decks
   - Unique cards per deck
   - Card quantities across decks
6. Handle complex card layouts (transform, modal DFC, split, aftermath, etc.)
7. Dark/light/auto theme toggle

## Technical Notes

- **Redis**: Used for caching Scryfall API responses, rate limiting (10 req/s), and storing manual decks (30-day TTL)
- **Case Conversion**: Frontend uses camelCase, backend uses snake_case - automatically converted via middleware
- **ServiceRegistry**: Shared connection pool for Redis accessed via `ServiceRegistry.redis`
- **Card Comparison**: Uses `CardKey` model for comparing cards (by set/number or name fallback)
- **Environment**: Requires `REDIS_URL` environment variable (SSL configured for production)
- **Manual deck URL scheme**: `mtg-deck-compare://manualDeck/<uuid>` — recognized by `DeckService#load_from_url` to load from Redis
- **DeckService**: Loads decks from URLs and saves manual decks; `save_manual_deck` parses text, fetches cards via Scryfall, and persists the result. Cards Scryfall can't match are logged and skipped instead of failing the deck
- **Logging**: `AppLogger` logs every deck-source fetch (`fetch source=... status=... ms=... url=...`), which makes blocks visible in production logs
- **Dockerfile**: Multi-stage build with separate frontend/backend dev and production targets; production image bundles the built frontend into the Ruby server image

## Development Workflow

1. Start backend: `bundle exec rackup -p 9292`
2. Start frontend: `npm run dev`
3. Frontend proxy will route API calls to backend
4. Run `npm run type-check` and `npm run lint` before commits