# Local Development Guide

This guide explains how to run Music Graph on your local machine for development.

## Two Ways to Run Locally

| Method | Database | Best For |
|--------|----------|----------|
| `python app.py` | SQLite (file) | Quick testing, no Docker needed |
| `docker compose up` | PostgreSQL (container) | Full stack, matches production |

## Prerequisites

- Python 3.12+
- Git
- Docker and Docker Compose (for container method)

## Method 1: Python Virtual Environment (SQLite)

This is the simplest way to get started. Uses SQLite (a file-based database) so there's nothing to install.

### Setup

```bash
# Clone the repository
git clone https://github.com/billgrant/music-graph.git
cd music-graph

# Create and activate virtual environment
python3 -m venv .venv
source .venv/bin/activate  # Linux/Mac
# or: .venv\Scripts\activate  # Windows

# Install dependencies
pip install -r requirements.txt

# Initialize the database with sample data
python init_db.py
```

### Running

```bash
# Activate virtual environment (if not already active)
source .venv/bin/activate

# Start the development server
python app.py
```

Visit http://localhost:5000

### What Happens

1. Flask starts in development mode with auto-reload
2. SQLite database is created at `music_graph.db` in the project root
3. No `DATABASE_URL` is set, so `config.py` falls back to SQLite
4. `SECRET_KEY` uses the development fallback value

### Resetting the Database

```bash
# Delete the database file and reinitialize
rm music_graph.db
python init_db.py
```

### Default Admin User

After running `init_db.py`:
- Username: `admin`
- Password: `admin123`

---

## Method 2: Docker Compose (PostgreSQL)

This method runs the full stack in containers, matching the production environment more closely.

### Setup

```bash
# Clone the repository
git clone https://github.com/billgrant/music-graph.git
cd music-graph

# Build and start containers
docker compose up -d --build
```

### What Happens

1. Docker Compose starts two containers:
   - `db`: PostgreSQL 16 database
   - `web`: Flask application with Gunicorn
2. PostgreSQL data is persisted in a Docker volume (`postgres_data`)
3. The web container waits for PostgreSQL to be healthy before starting
4. `entrypoint.sh` detects that `DATABASE_URL` is already set and skips fetching secrets from GCP
5. Gunicorn serves the app on port 5000 with 2 workers

### First Run - Initialize Database

On first run, or if you deleted the volume, initialize the database:

```bash
docker compose exec web python init_db.py
```

### Accessing the App

Visit http://localhost:5000

### Useful Commands

```bash
# View logs
docker compose logs -f web
docker compose logs -f db

# Stop containers (keeps data)
docker compose down

# Stop and remove data volume (fresh start)
docker compose down -v

# Rebuild after code changes
docker compose down
docker compose up -d --build

# Access PostgreSQL directly
docker compose exec db psql -U musicgraph -d musicgraph

# Run database migrations
docker compose exec web python init_db.py

# Make a user admin
docker compose exec web python make_admin.py <username>
```

### Environment Variables

The `docker-compose.yml` sets these environment variables:

| Variable | Value | Purpose |
|----------|-------|---------|
| `DATABASE_URL` | `postgresql://musicgraph:...@db:5432/musicgraph` | PostgreSQL connection string |
| `SECRET_KEY` | `dev-secret-key-change-in-production` | Flask session signing |
| `POSTGRES_PASSWORD` | `musicgraph_dev_password` | PostgreSQL password |

---

## Comparison: SQLite vs PostgreSQL

| Feature | SQLite (python app.py) | PostgreSQL (docker compose) |
|---------|------------------------|----------------------------|
| Setup time | ~1 minute | ~2 minutes |
| Dependencies | Python only | Docker required |
| Database location | `music_graph.db` file | Docker volume |
| Auto-reload | Yes (Flask dev server) | No (Gunicorn) |
| Matches production | Somewhat | Closely |
| Best for | Quick edits, testing | Full integration testing |

### When to Use Which

**Use `python app.py` when:**
- Making quick UI changes
- Testing Flask routes
- You don't have Docker installed
- You want auto-reload on code changes

**Use `docker compose` when:**
- Testing database migrations
- Testing the full deployment pipeline
- You want to match production behavior
- Testing `entrypoint.sh` changes

---

## Running Tests

Tests use SQLite regardless of which method you use for development:

```bash
# Activate virtual environment
source .venv/bin/activate

# Run all tests
pytest

# Run with coverage
pytest --cov=. --cov-report=term-missing

# Run specific test file
pytest tests/test_app.py

# Run with verbose output
pytest -v
```

---

## Troubleshooting

### Port 5000 already in use

```bash
# Find what's using port 5000
lsof -i :5000

# Kill the process or use a different port
python app.py --port 5001
```

### Docker container won't start

```bash
# Check logs
docker compose logs web

# Common issues:
# - Database not initialized: run `docker compose exec web python init_db.py`
# - Port conflict: stop other services using port 5000
# - Stale image: rebuild with `docker compose up -d --build`
```

### Module not found errors

```bash
# Make sure you're in the virtual environment
source .venv/bin/activate

# Reinstall dependencies
pip install -r requirements.txt
```

### Database schema errors

```bash
# SQLite: delete and reinitialize
rm music_graph.db
python init_db.py

# Docker: remove volume and reinitialize
docker compose down -v
docker compose up -d
docker compose exec web python init_db.py
```

---

## Architecture Notes

### config.py Logic

```python
# Uses DATABASE_URL if set, otherwise falls back to SQLite
SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL') or \
    'sqlite:///' + os.path.join(basedir, 'music_graph.db')
```

### entrypoint.sh Logic

The container entrypoint script checks if secrets are already set:

```bash
if [ -n "$SECRET_KEY" ] && [ -n "$DATABASE_URL" ]; then
    echo "Secrets already set (Cloud Run or local dev) - skipping fetch"
```

This means:
- **Local docker compose**: Secrets are set via environment variables in `docker-compose.yml`, so no GCP access needed
- **Cloud Run**: Secrets are injected by the platform
- **GCP VMs**: Secrets are fetched from Secret Manager via metadata server

---

## Next Steps

Once you have local development working:
1. Make changes and test locally
2. Run tests with `pytest`
3. Push to GitHub - CI will run automatically
4. Dev environment deploys automatically on push to main
5. Production deploys via manual GitHub Actions trigger
