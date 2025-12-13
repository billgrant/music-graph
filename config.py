import os

basedir = os.path.abspath(os.path.dirname(__file__))

class Config:
    # SECRET_KEY: Required in production (set via entrypoint.sh from Secret Manager)
    # Fallback only used for local development (python app.py on laptop)
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'local-dev-only-not-for-production'

    # Use PostgreSQL if DATABASE_URL is set, otherwise SQLite for local dev
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL') or \
        'sqlite:///' + os.path.join(basedir, 'music_graph.db')

    SQLALCHEMY_TRACK_MODIFICATIONS = False