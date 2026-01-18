FROM node:24-bookworm-slim as frontend_base

WORKDIR /app

COPY ./package.json ./package-lock.json ./

RUN npm ci

COPY web ./web
COPY vite.config.ts ./
COPY tsconfig*.json ./
COPY postcss.config.js ./
COPY env.d.ts ./

FROM node:24-bookworm-slim as frontend_dev
WORKDIR /app

COPY --from=frontend_base /app ./
EXPOSE 5173
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0", "--port", "5173"]

FROM node:24-bookworm-slim as frontend_production
WORKDIR /app

COPY --from=frontend_base /app ./
RUN npm run build

FROM ruby:3.3.2-bookworm as server_base
WORKDIR /app

COPY Gemfile Gemfile.lock ./
COPY server ./server
COPY config ./config
COPY config.ru ./

RUN mkdir -p tmp
RUN mkdir -p -m 766 /selenium_cache

ENV SE_CACHE_PATH=/selenium_cache

FROM ruby:3.3.2-bookworm as server_dev
WORKDIR /app

RUN apt-get update && apt-get install -y \
  build-essential \
  libpq-dev \
  curl \
  libnss3 \
  libnspr4 \
  libatk1.0-0 \
  libatk-bridge2.0-0 \
  libcups2 \
  libdrm2 \
  libgtk-3-0 \
  libgbm1 \
  libasound2 \
  && rm -rf /var/lib/apt/lists/*

COPY --from=server_base /app ./
COPY .env ./
RUN bundle install

CMD ["bundle", "exec", "rackup", "--host", "0.0.0.0", "--port", "9292"]
FROM ruby:3.3.2-bookworm as server_production
WORKDIR /app

RUN apt-get update && apt-get install -y \
  build-essential \
  libpq-dev \
  curl \
  libnss3 \
  libnspr4 \
  libatk1.0-0 \
  libatk-bridge2.0-0 \
  libcups2 \
  libdrm2 \
  libgtk-3-0 \
  libgbm1 \
  libasound2 \
  && rm -rf /var/lib/apt/lists/*

COPY --from=server_base /app ./
COPY --from=frontend_production /app/public ./public

RUN bundle config set --local deployment 'true' && \
  bundle config set --local without 'development test' && \
  bundle install

ENV RACK_ENV=production

EXPOSE 8080

CMD ["bundle", "exec", "rackup", "--host", "0.0.0.0", "--port", "8080"]