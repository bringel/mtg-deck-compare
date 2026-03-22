# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture

This is a full-stack Magic: The Gathering deck comparison application with a Ruby/Sinatra backend and Vue 3/TypeScript frontend.

**Backend (Ruby/Sinatra)**:
- `server/api_app.rb` - Main API application with all endpoints
- `server/static_app.rb` - Serves the frontend SPA, handles all routes with `index.html`
- `config.ru` - Rack configuration mapping `/api` to `ApiApp` and `/` to `StaticApp`
- `server/lib/deck_comparer.rb` - Core comparison logic across multiple decks
- `server/lib/service_registry.rb` - Shared service locator (Redis connection pool)
- `server/services/deck_service.rb` - Deck persistence/retrieval via Redis
- `server/services/cards_service.rb` - Card fetching from Scryfall with caching
- `server/services/scryfall_service.rb` - Scryfall API client with rate limiting
- `server/decklist_parsers/` - Site-specific parsers (see below)
- `server/middleware/` - Rack middleware for case conversion and rate limiting
- `server/models/` - Data models: `Card`, `Deck`, `CardKey`

**Frontend (Vue 3/TypeScript)**:
- Located in `web/` with Vite build system
- API proxy in `vite.config.ts` routes `/api` → `http://localhost:9292`
- Builds to `public/` directory, served by `StaticApp` in production
- Tailwind CSS v4 for styling
- Pinia for state management, Vue Router for routing

## Development Commands

**Backend (Ruby)**:
```bash
bundle install
bundle exec rackup -p 9292
```

**Frontend (Vue/TypeScript)**:
```bash
npm install
npm run dev         # Dev server with hot reload (port 5173)
npm run type-check  # TypeScript type checking
npm run lint        # ESLint with auto-fix
npm run build       # Production build → public/
npm run format      # Prettier format web/src/
```

**Docker (recommended for local dev)**:
```bash
docker-compose up   # Starts Redis, Vite dev server, and Sinatra backend
```
Services: Redis on `6379`, Vite dev on `5173`, backend on `9292`.

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `REDIS_URL` | Yes | Redis/Valkey connection URL |
| `MOXFIELD_USER_AGENT` | Yes (production) | Custom User-Agent for Moxfield API requests |
| `RACK_ENV` | No | `development` or `production` |

For local dev, create a `.env` file (loaded via `dotenv` gem).

## Supported Decklist Sites

Parsers live in `server/decklist_parsers/`. Each subclasses `DecklistParser` and implements `URL_PATTERN`, `deck_name`, `author`, `card_hashes`, and `source_type`.

| Parser | Site | Notes |
|---|---|---|
| `MoxfieldParser` | moxfield.com | Requires `MOXFIELD_USER_AGENT` env var |
| `ArchidektParser` | archidekt.com | |
| `AetherhubParser` | aetherhub.com | |
| `DeckstatsParser` | deckstats.net | |
| `MtggoldfishParser` | mtggoldfish.com | |
| `MtgDecksParser` | mtgdecks.net | Scrapes HTML with Nokogiri |
| `ManualDeckParser` | `mtg-deck-compare://manualDeck/<uuid>` | Internal URI for user-pasted decklists |

`ParserList.get_parser(url)` selects the correct parser by matching the URL against each parser's `URL_PATTERN`.

`TextListParser` is a shared utility (not a full parser) that parses raw decklist text into card hashes. It supports formats like `1 Lightning Bolt`, `Lightning Bolt 1`, and `1 Lightning Bolt (M10) 145`. Used by `MtgDecksParser` and `DeckService#save_manual_deck`.

## API Endpoints

All under `/api` (mounted via `config.ru`):

| Method | Path | Description |
|---|---|---|
| `GET` | `/deck_info?url=<url>` | Basic deck metadata (name, format, etc.) |
| `GET` | `/load_deck?url=<url>` | Full deck data (cards, quantities) |
| `POST` | `/compare_decks` | Compare decks — body: `{deckListUrls: [...]}` |
| `POST` | `/create_manual_deck` | Save a pasted decklist — body: `{list, name, author}` |
| `GET` | `/check_card/:set/:number` | Single card data from Scryfall |
| `POST` | `/check_cards` | Batch card fetch — body: array of `{set_code, set_number}` |

**Note**: Middleware automatically converts request bodies from camelCase → snake_case and response bodies from snake_case → camelCase. The frontend always uses camelCase; the backend always uses snake_case.

## Frontend Structure

```
web/src/
├── App.vue                    # Root component, router-view
├── Home.vue                   # URL input page
├── Compare.vue                # Comparison results page
├── router/index.ts            # Routes: / (Home), /compare (Compare)
├── store/
│   ├── deckStore.ts           # Deck loading state (Pinia)
│   └── deckComparisonStore.ts # Comparison results state (Pinia)
├── components/
│   ├── AppShell.vue           # Layout wrapper with HeaderBar
│   ├── DeckComparison.vue     # Main comparison UI
│   ├── ComparisonSection.vue  # Common/multiple cards section
│   ├── RemainingDeckList.vue  # Unique-per-deck cards
│   ├── ManualDeckModal.vue    # Paste-a-decklist modal
│   ├── Card.vue               # Card display with hover image
│   ├── FloatingCardImage.vue  # Hoverable card image popup
│   ├── ManaCost.vue           # Mana symbol rendering
│   └── ...                    # Other UI components
├── types/                     # TypeScript interfaces
│   ├── Card.ts, Deck.ts, DeckComparison.ts, etc.
├── lib/
│   ├── queryStringDeckURLs.ts # Base64 encode/decode deck URLs for sharing
│   ├── cardTypeSorter.ts      # Sort cards by type
│   ├── deckColors.ts          # MTG color identity utilities
│   └── bingo.ts               # Bingo card generation feature
└── composables/
    └── useTheme.ts            # Light/dark theme toggle
```

**URL sharing**: Deck URLs are serialized as `btoa(JSON.stringify(urls))` and stored in the query string. Use `encodeDeckURLs`/`decodeDeckURLs` from `queryStringDeckURLs.ts`.

**Manual decks**: Created via `POST /api/create_manual_deck`, stored in Redis for 30 days, referenced by a `mtg-deck-compare://manualDeck/<uuid>` URI that the frontend treats like any other deck URL.

## Redis / Caching

- No persistent database — all data is cached in Redis/Valkey
- Remote decks cached for **5 minutes** (key: `decks:<url>`)
- Manual decks cached for **30 days** (key: `decks:manual:<uuid>`)
- Scryfall API responses cached to respect rate limits (10 req/sec via `RateLimiter` middleware)
- `ServiceRegistry.redis` provides a thread-safe `ConnectionPool::Wrapper`

**Production**: Uses DigitalOcean Valkey (Redis-compatible). SSL verification is disabled (`VERIFY_NONE`) for the connection.

## Deployment

**Production stack**: DigitalOcean App Platform (see `.do/app.yaml`)
- Domain: `mtgdeckcompare.com`
- Image: GHCR (`ghcr.io/bringel/mtg-deck-compare`)
- Redis: DigitalOcean Valkey cluster
- Server runs on port **8080** in production

**Dockerfile** uses multi-stage builds:
- `frontend_base` → `frontend_dev` (dev) or `frontend_production` (build assets)
- `server_base` → `server_dev` (dev) or `server_production` (production, includes built frontend)

## Key Technical Notes

- **Ruby version**: 3.3.2 (see `Gemfile`)
- **Node version**: 24 (see `Dockerfile`)
- **Card comparison**: Uses `CardKey` model — cards are matched by `set_code + set_number` when available, falling back to name
- **DeckComparer output**: `{ common: {main_deck, sideboard}, multiple: {main_deck, sideboard}, decks_remaining: {<index>: {main_deck, sideboard}} }`
- **Database migrations**: `server/db/migrations/` contains Sequel migrations for a PostgreSQL schema that is **currently commented out** (the DB lines in `api_app.rb` are disabled). The app runs Redis-only.
- **Scraping**: `MtgDecksParser` uses Faraday + Nokogiri to scrape HTML. `selenium-webdriver` and `capybara` gems are present for potential browser-based scraping.
- **Frozen string literals**: All Ruby files use `# frozen_string_literal: true`

## Development Workflow

1. Copy `.env.example` → `.env` with your `REDIS_URL` (or run `docker-compose up redis`)
2. Start backend: `bundle exec rackup -p 9292`
3. Start frontend: `npm run dev`
4. Frontend dev proxy routes `/api` calls to the backend automatically
5. Before committing, run:
   ```bash
   npm run type-check
   npm run lint
   ```

## Adding a New Decklist Parser

1. Create `server/decklist_parsers/<site>_parser.rb` subclassing `DecklistParser`
2. Define `URL_PATTERN` constant (Regexp matching the site's deck URLs)
3. Implement: `deck_name`, `author`, `card_hashes`, `source_type`
4. `card_hashes` must return `{ main_deck: [...], sideboard: [...], commander: [...] }` where each entry is `{ quantity:, name:, set_code: (optional), set_number: (optional) }`
5. Add to `PARSERS` array in `server/decklist_parsers/parser_list.rb`
6. Add a `require_relative` for the new file in `parser_list.rb`
