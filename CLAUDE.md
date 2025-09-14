# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture

This is a full-stack Magic: The Gathering deck comparison application with a Ruby/Sinatra backend and Vue 3/TypeScript frontend.

**Backend (Ruby/Sinatra)**:
- `server/api_app.rb` - Main API application with endpoints for deck loading and comparison
- `server/static_app.rb` - Serves the frontend SPA, handles all routes with index.html
- `config.ru` - Rack configuration mapping `/api` to ApiApp and `/` to StaticApp
- Database: PostgreSQL with Sequel ORM, includes custom `read_through_database` extension
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

# Run database migrations
bundle exec rake db:migrate

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

**Database**:
- Migrations located in `server/db/migrations/`
- Use `bundle exec rake db:migrate` to run migrations
- PostgreSQL connection configured via `DATABASE_URL` environment variable

## Project Structure

- `/server/` - Ruby backend code
  - `/api_app.rb` - Main API endpoints
  - `/models/` - Sequel models (Card, Deck)
  - `/services/` - External service integrations (Scryfall API)
  - `/decklist_parsers/` - Parsers for different MTG sites
  - `/lib/` - Core business logic and extensions
- `/web/` - Vue 3 frontend
  - `/src/components/` - Vue components
  - `/src/lib/` - Frontend utilities
- `/public/` - Built frontend assets (generated)
- `config.ru` - Rack application configuration

## Key Features

The application allows users to:
1. Input multiple MTG decklist URLs from supported sites
2. Parse and load deck data using site-specific parsers
3. Compare decks to find:
   - Cards common to all decks
   - Cards appearing in multiple (but not all) decks
   - Unique cards per deck
   - Card quantities across decks

## Development Workflow

1. Start backend: `bundle exec rackup -p 9292`
2. Start frontend: `npm run dev`
3. Frontend proxy will route API calls to backend
4. Run `npm run type-check` and `npm run lint` before commits