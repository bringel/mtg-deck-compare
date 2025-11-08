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
```

**Frontend (Vue/TypeScript)**:
```bash
# Install dependencies
npm install

# Start development server with hot reload
npm run dev

# Type checking
npm run type-check

# Linting
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

Each parser handles site-specific deck formats and normalizes them into a common structure.

## API Endpoints

- `GET /api/deck_info?url=<deck_url>` - Get basic deck information (name, format, etc.)
- `GET /api/load_deck?url=<deck_url>` - Load full deck data
- `POST /api/compare_decks` - Compare multiple decks (expects `{deckListUrls: [...]}`)
- `GET /api/check_card/:set/:number` - Get card data from Scryfall
- `POST /api/check_cards` - Batch fetch card data

## Project Structure

- `/server/` - Ruby backend code
  - `/api_app.rb` - Main API endpoints
  - `/models/` - Data models (Card, Deck, CardKey)
  - `/services/` - External service integrations (Scryfall API with rate limiting)
  - `/decklist_parsers/` - Site-specific parsers for different MTG deck sites
  - `/lib/` - Core business logic (DeckComparer, ServiceRegistry)
  - `/middleware/` - Rack middleware (rate limiting, case conversion)
- `/web/` - Vue 3 frontend
  - `/src/components/` - Vue components
  - `/src/lib/` - Frontend utilities
- `/public/` - Built frontend assets (generated)
- `config.ru` - Rack application configuration

## Key Features

The application allows users to:
1. Input multiple MTG decklist URLs from supported sites
2. Parse and load deck data using site-specific parsers
3. Fetch card images and metadata from Scryfall API (with rate limiting)
4. Compare decks to find:
   - Cards common to all decks
   - Cards appearing in multiple (but not all) decks
   - Unique cards per deck
   - Card quantities across decks
5. Handle complex card layouts (transform, modal DFC, split, aftermath, etc.)

## Technical Notes

- **Redis**: Used for caching Scryfall API responses and rate limiting (10 requests/second)
- **Case Conversion**: Frontend uses camelCase, backend uses snake_case - automatically converted via middleware
- **ServiceRegistry**: Shared connection pool for Redis accessed via `ServiceRegistry.redis`
- **Card Comparison**: Uses `CardKey` model for comparing cards (by set/number or name fallback)
- **Environment**: Requires `REDIS_URL` environment variable (SSL configured for production)

## Development Workflow

1. Start backend: `bundle exec rackup -p 9292`
2. Start frontend: `npm run dev`
3. Frontend proxy will route API calls to backend
4. Run `npm run type-check` and `npm run lint` before commits