# Ultrastore Backend

Headless WordPress + WooCommerce setup with Docker.

## Quick Start

1. **Clone and setup:**
   ```bash
   git clone <your-repo-url>
   cd ultrastore-backend
   ./scripts/setup-local.sh
   ```

2. **Access:**
   - Site: http://localhost:8080
   - Admin: http://localhost:8080/wp-admin
   - Username: `admin`
   - Password: `admin`

## Daily Commands

```bash
# Start
docker-compose up -d

# Stop
docker-compose down

# View logs
docker-compose logs -f wordpress

# WP-CLI
docker-compose exec wordpress wp --allow-root <command>
```

## API Endpoints

- WordPress API: `http://localhost:8080/wp-json/wp/v2/`
- WooCommerce API: `http://localhost:8080/wp-json/wc/v3/`

## Deployment

### Manual
```bash
./scripts/deploy-theme.sh
```

### Automatic (GitHub Actions)
Push to `main` branch. Theme changes auto-deploy.

**Required GitHub Secrets:**
- `SSH_HOST`: shop.ultrastore.khizrim.online
- `SSH_USER`: root
- `SSH_KEY`: Your SSH private key

## Project Structure

```
themes/ultrastore-headless/  # Your theme
scripts/                     # Setup & deploy scripts
docker-compose.yml          # Docker config
.env                       # Environment vars (don't commit!)
```

## Troubleshooting

**Reset everything:**
```bash
docker-compose down -v
./scripts/setup-local.sh
```
