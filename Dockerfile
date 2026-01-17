# Multi-stage build for MTG Deck Compare application

# Stage 1: Build frontend with Node.js
FROM node:22-alpine AS frontend-builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy frontend source
COPY web ./web
COPY vite.config.ts ./
COPY tsconfig*.json ./
COPY tailwind.config.js ./
COPY postcss.config.mjs ./
COPY index.html ./

# Build the Vue application
RUN npm run build

# Stage 2: Ruby application
FROM ruby:3.3.2-slim

# Install system dependencies including Chrome for Selenium
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    chromium \
    chromium-driver \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy Ruby dependencies
COPY Gemfile Gemfile.lock ./

# Install Ruby gems
RUN bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    bundle install

# Copy application code
COPY server ./server
COPY config ./config
COPY config.ru ./
COPY CLAUDE.md ./

# Copy built frontend from builder stage
COPY --from=frontend-builder /app/public ./public

# Create tmp directory for Rack
RUN mkdir -p tmp

# Set environment variables
ENV RACK_ENV=production
ENV PORT=9292

# Expose port
EXPOSE 9292

# Start the application with Puma
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
