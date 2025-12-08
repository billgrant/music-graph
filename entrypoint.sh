#!/bin/bash
set -e

echo "Waiting for PostgreSQL..."
until PGPASSWORD=$POSTGRES_PASSWORD psql -h "db" -U "musicgraph" -c '\q' 2>/dev/null; do
  echo "Waiting for database connection..."
  sleep 1
done

echo "PostgreSQL ready!"

# Check if database is already initialized
echo "Checking if database needs initialization..."
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

# If previous command failed (exit code 1), initialize database
if [ $? -eq 1 ]; then
    echo "Initializing database..."
    python init_db.py || {
        echo "ERROR: Database initialization failed!"
        exit 1
    }
else
    echo "Skipping database initialization (already exists)"
fi

# Start application
echo "Starting application..."
exec python app.py