# Ultrastore Backend

WordPress/WooCommerce backend for Apple products store.

## Quick Start

1. **Clone and navigate:**
   ```bash
   git clone <repo-url>
   cd ultrastore-backend
   ```

2. **Start containers:**
   ```bash
   docker-compose up -d
   ```

3. **Run setup script:**
   ```bash
   ./scripts/setup.sh
   ```

4. **Access the store:**
   - WordPress Admin: http://localhost:8080/wp-admin
   - API: http://localhost:8080/wp-json/wc/v3/
   - Default login: `admin` / `admin`

## What you get

- ✅ WordPress + WooCommerce
- ✅ Headless-ready configuration
- ✅ REST API enabled

## Stop containers

```bash
docker-compose down
```

## Reset everything

```bash
docker-compose down -v
docker-compose up -d
./scripts/setup.sh
```