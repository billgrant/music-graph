#!/bin/bash
set -e

# =============================================================================
# Fetch secrets from GCP Secret Manager (if running in GCP)
# Uses metadata server for auth - no gcloud CLI needed
# =============================================================================

fetch_gcp_secret() {
    local secret_name=$1
    local project_id=$2
    local token=$3

    # Fetch secret from Secret Manager API
    local response=$(curl -s "https://secretmanager.googleapis.com/v1/projects/${project_id}/secrets/${secret_name}/versions/latest:access" \
        -H "Authorization: Bearer ${token}")

    # Extract and decode the secret value (base64 encoded in response)
    echo "$response" | python3 -c "import sys,json,base64; print(base64.b64decode(json.load(sys.stdin)['payload']['data']).decode())"
}

# Check if running in GCP by testing metadata server
if curl -s -f -m 2 "http://metadata.google.internal/computeMetadata/v1/" -H "Metadata-Flavor: Google" > /dev/null 2>&1; then
    echo "Running in GCP - fetching secrets from Secret Manager..."

    # Get project ID from metadata
    PROJECT_ID=$(curl -s "http://metadata.google.internal/computeMetadata/v1/project/project-id" -H "Metadata-Flavor: Google")

    # Get access token from metadata server
    TOKEN=$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token" \
        -H "Metadata-Flavor: Google" | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

    # Determine environment (default to prod if not set)
    ENV="${ENVIRONMENT:-prod}"
    echo "Environment: ${ENV}"

    # Fetch secrets
    export SECRET_KEY=$(fetch_gcp_secret "music-graph-${ENV}-secret-key" "$PROJECT_ID" "$TOKEN")
    export DATABASE_URL=$(fetch_gcp_secret "music-graph-${ENV}-database-url" "$PROJECT_ID" "$TOKEN")

    echo "Secrets loaded from Secret Manager"
else
    echo "Not running in GCP - using environment variables from docker-compose"
fi

# =============================================================================
# Wait for PostgreSQL and start application
# =============================================================================

echo "Waiting for PostgreSQL..."
until python3 -c "
from sqlalchemy import create_engine, text
import os
engine = create_engine(os.environ['DATABASE_URL'])
with engine.connect() as conn:
    conn.execute(text('SELECT 1'))
" 2>/dev/null; do
  echo "Waiting for database connection..."
  sleep 1
done

echo "PostgreSQL ready!"

# Check if database is already initialized
echo "Checking if database needs initialization..."
set +e  # Temporarily disable exit on error
python -c "
from app import app
from models import db, Genre
with app.app_context():
    try:
        # Try to query a table - if it works, DB is initialized
        Genre.query.first()
        print('Database tables exist')
        exit(0)
    except Exception as e:
        print(f'Database needs initialization: {e}')
        exit(1)
"
DB_CHECK_EXIT=$?
set -e  # Re-enable exit on error

# If previous command failed (exit code 1), initialize database
if [ $DB_CHECK_EXIT -eq 1 ]; then
    echo "Initializing database..."
    python init_db.py || {
        echo "ERROR: Database initialization failed!"
        exit 1
    }
else
    echo "Skipping database initialization (already exists)"
fi

# Start application with Gunicorn (production WSGI server)
echo "Starting application with Gunicorn..."
exec gunicorn --bind 0.0.0.0:5000 --workers 2 app:app