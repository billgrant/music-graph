#!/bin/bash
set -e

echo "Waiting for PostgreSQL..."
until PGPASSWORD=$POSTGRES_PASSWORD psql -h "db" -U "musicgraph" -c '\q' 2>/dev/null; do
  sleep 1
done

echo "PostgreSQL ready!"

# Initialize database if needed
echo "Initializing database..."
python init_db.py

# Start application
echo "Starting application..."
exec python app.py
