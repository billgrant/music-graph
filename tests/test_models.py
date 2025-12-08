"""Tests for database models."""
import pytest
from models import Genre, Band, User, db


def test_genre_creation(app):
    """Test creating a genre."""
    with app.app_context():
        genre = Genre(id='test-genre', name='Test Genre', type='leaf')
        db.session.add(genre)
        db.session.commit()

        retrieved = db.session.get(Genre, 'test-genre')
        assert retrieved is not None
        assert retrieved.name == 'Test Genre'
        assert retrieved.type == 'leaf'


def test_genre_parent_relationship(app, sample_genres):
    """Test genre parent-child relationships."""
    with app.app_context():
        metal = db.session.get(Genre, 'metal')
        death_metal = db.session.get(Genre, 'death-metal')

        assert death_metal.parent_id == 'metal'
        assert death_metal.parent == metal
        assert death_metal in metal.children


def test_genre_multiple_parents(app, sample_genres):
    """Test genre with multiple parent genres."""
    with app.app_context():
        # Create a genre with multiple parents (like Grindcore)
        metal = db.session.get(Genre, 'metal')
        hardcore = Genre(id='hardcore', name='Hardcore', type='intermediate', parent_id='rock')
        grindcore = Genre(id='grindcore', name='Grindcore', type='leaf', parent_id='metal')

        db.session.add(hardcore)
        db.session.add(grindcore)
        db.session.commit()

        # Add multiple parents
        grindcore.parent_genres.append(metal)
        grindcore.parent_genres.append(hardcore)
        db.session.commit()

        # Verify
        retrieved = db.session.get(Genre, 'grindcore')
        assert len(retrieved.parent_genres) == 2
        assert metal in retrieved.parent_genres
        assert hardcore in retrieved.parent_genres


def test_band_creation(app, sample_genres):
    """Test creating a band."""
    with app.app_context():
        death_metal = db.session.get(Genre, 'death-metal')
        band = Band(id='test-band', name='Test Band', primary_genre_id='death-metal')
        band.genres.append(death_metal)

        db.session.add(band)
        db.session.commit()

        retrieved = db.session.get(Band, 'test-band')
        assert retrieved is not None
        assert retrieved.name == 'Test Band'
        assert retrieved.primary_genre_id == 'death-metal'
        assert death_metal in retrieved.genres


def test_band_multiple_genres(app, sample_genres):
    """Test band with multiple genres."""
    with app.app_context():
        death_metal = db.session.get(Genre, 'death-metal')
        black_metal = db.session.get(Genre, 'black-metal')

        band = Band(id='multi-genre-band', name='Multi Genre Band', primary_genre_id='death-metal')
        band.genres.append(death_metal)
        band.genres.append(black_metal)

        db.session.add(band)
        db.session.commit()

        retrieved = db.session.get(Band, 'multi-genre-band')
        assert len(retrieved.genres) == 2
        assert death_metal in retrieved.genres
        assert black_metal in retrieved.genres


def test_user_password(app):
    """Test user password hashing and verification."""
    with app.app_context():
        user = User(username='testuser', email='test@example.com')
        user.set_password('testpassword')

        db.session.add(user)
        db.session.commit()

        retrieved = User.query.filter_by(username='testuser').first()
        assert retrieved is not None
        assert retrieved.check_password('testpassword') is True
        assert retrieved.check_password('wrongpassword') is False


def test_user_admin_flag(app):
    """Test user admin flag."""
    with app.app_context():
        admin = User(username='admin', email='admin@example.com', is_admin=True)
        admin.set_password('admin123')
        regular = User(username='regular', email='regular@example.com', is_admin=False)
        regular.set_password('regular123')

        db.session.add_all([admin, regular])
        db.session.commit()

        admin_retrieved = User.query.filter_by(username='admin').first()
        regular_retrieved = User.query.filter_by(username='regular').first()

        assert admin_retrieved.is_admin is True
        assert regular_retrieved.is_admin is False
