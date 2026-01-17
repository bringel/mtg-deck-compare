# mtg-deck-compare

## Running with Docker

### Prerequisites
- Docker
- Docker Compose

### Quick Start

Build and run the application with Docker Compose:

```bash
docker-compose up --build
```

The application will be available at http://localhost:9292

### Docker Services

- **web**: The main application (Ruby/Sinatra backend + Vue frontend)
- **redis**: Redis cache for Scryfall API responses and rate limiting

### Environment Variables

The following environment variables can be configured in `docker-compose.yml`:

- `REDIS_URL`: Redis connection URL (default: `redis://redis:6379`)
- `RACK_ENV`: Rack environment (default: `production`)
- `PORT`: Port to run the web server on (default: `9292`)

### Building the Docker Image

To build the Docker image separately:

```bash
docker build -t mtg-deck-compare .
```

### Running Without Docker Compose

To run the container manually (requires a separate Redis instance):

```bash
docker run -p 9292:9292 -e REDIS_URL=redis://your-redis-host:6379 mtg-deck-compare
```