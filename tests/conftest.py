"""Pytest configuration and fixtures for Music Graph tests."""
import pytest
import os
import tempfile

# Set test database BEFORE importing app - this is critical!
# The app reads DATABASE_URL from environment on import
_db_fd, _db_path = tempfile.mkstemp(suffix='.db')
os.environ['DATABASE_URL'] = f'sqlite:///{_db_path}'

from app import app as flask_app, limiter
from models import db, Genre, Band, User

# Disable rate limiting for tests
limiter.enabled = False


@pytest.fixture
def app():
    """Create and configure a test Flask application instance."""
    flask_app.config.update({
        'TESTING': True,
        'SECRET_KEY': 'test-secret-key',
        'WTF_CSRF_ENABLED': False,
        'RATELIMIT_ENABLED': False  # Disable rate limiting during tests
    })

    with flask_app.app_context():
        db.create_all()
        yield flask_app
        db.session.remove()
        db.drop_all()


@pytest.fixture
def client(app):
    """A test client for the app."""
    return app.test_client()


@pytest.fixture
def runner(app):
    """A test CLI runner for the app."""
    return app.test_cli_runner()


@pytest.fixture
def sample_genres(app):
    """Create sample genres for testing."""
    with app.app_context():
        # Create root genre
        rock = Genre(id='rock', name='Rock', type='root')

        # Create intermediate genre
        metal = Genre(id='metal', name='Metal', type='intermediate', parent_id='rock')

        # Create leaf genres
        death_metal = Genre(id='death-metal', name='Death Metal', type='leaf', parent_id='metal')
        black_metal = Genre(id='black-metal', name='Black Metal', type='leaf', parent_id='metal')

        db.session.add_all([rock, metal, death_metal, black_metal])
        db.session.commit()

        return {
            'rock': rock,
            'metal': metal,
            'death_metal': death_metal,
            'black_metal': black_metal
        }


@pytest.fixture
def sample_bands(app, sample_genres):
    """Create sample bands for testing."""
    with app.app_context():
        # Refresh the genre objects in this session
        death_metal = db.session.get(Genre, 'death-metal')
        black_metal = db.session.get(Genre, 'black-metal')

        death_band = Band(
            id='death',
            name='Death',
            primary_genre_id='death-metal'
        )
        death_band.genres.append(death_metal)

        dimmu_borgir = Band(
            id='dimmu-borgir',
            name='Dimmu Borgir',
            primary_genre_id='black-metal'
        )
        dimmu_borgir.genres.append(black_metal)

        db.session.add_all([death_band, dimmu_borgir])
        db.session.commit()

        return {
            'death': death_band,
            'dimmu_borgir': dimmu_borgir
        }


@pytest.fixture
def admin_user(app):
    """Create an admin user for testing."""
    with app.app_context():
        user = User(username='admin', email='admin@test.com', is_admin=True)
        user.set_password('admin123')
        db.session.add(user)
        db.session.commit()
        return user


@pytest.fixture
def regular_user(app):
    """Create a regular (non-admin) user for testing."""
    with app.app_context():
        user = User(username='testuser', email='test@test.com', is_admin=False)
        user.set_password('test123')
        db.session.add(user)
        db.session.commit()
        return user
