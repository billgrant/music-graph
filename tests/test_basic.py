"""Basic smoke tests to verify the application starts correctly."""
import pytest


def test_app_exists(app):
    """Test that the app instance exists."""
    assert app is not None


def test_app_is_testing(app):
    """Test that the app is in testing mode."""
    assert app.config['TESTING'] is True


def test_client_exists(client):
    """Test that the test client exists."""
    assert client is not None


def test_home_page_loads(client):
    """Test that the home page loads successfully."""
    response = client.get('/')
    assert response.status_code == 200


def test_login_page_loads(client):
    """Test that the login page loads successfully."""
    response = client.get('/login')
    assert response.status_code == 200
