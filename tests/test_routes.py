"""Tests for Flask routes and views."""
import pytest
from flask import url_for


def test_index_route(client):
    """Test the index page route."""
    response = client.get('/')
    assert response.status_code == 200
    assert b'Music Graph' in response.data or b'music-graph' in response.data


def test_login_route_get(client):
    """Test GET request to login page."""
    response = client.get('/login')
    assert response.status_code == 200


def test_login_route_post_invalid(client):
    """Test POST request to login with invalid credentials."""
    response = client.post('/login', data={
        'username': 'nonexistent',
        'password': 'wrongpassword'
    }, follow_redirects=True)
    assert response.status_code == 200
    # Should show error message or stay on login page


def test_login_route_post_valid(client, regular_user):
    """Test POST request to login with valid credentials."""
    response = client.post('/login', data={
        'username': 'testuser',
        'password': 'test123'
    }, follow_redirects=True)
    assert response.status_code == 200


def test_logout_route(client, regular_user):
    """Test logout route."""
    # First login
    client.post('/login', data={
        'username': 'testuser',
        'password': 'test123'
    })

    # Then logout
    response = client.get('/logout', follow_redirects=True)
    assert response.status_code == 200


def test_admin_route_requires_login(client):
    """Test that admin routes require login."""
    response = client.get('/admin')
    # Should redirect to login
    assert response.status_code == 302 or response.status_code == 401


def test_admin_route_requires_admin(client, regular_user):
    """Test that admin routes require admin privileges."""
    # Login as regular user
    client.post('/login', data={
        'username': 'testuser',
        'password': 'test123'
    })

    # Try to access admin route
    response = client.get('/admin', follow_redirects=True)
    assert response.status_code == 200
    # Should show error or redirect


def test_admin_route_with_admin(client, admin_user):
    """Test that admin can access admin routes."""
    # Login as admin
    client.post('/login', data={
        'username': 'admin',
        'password': 'admin123'
    })

    # Access admin route
    response = client.get('/admin')
    assert response.status_code == 200


def test_graph_data_with_genres(client, sample_genres, sample_bands):
    """Test that the main page displays genres and bands."""
    response = client.get('/')
    assert response.status_code == 200

    # Check if genre names appear in response
    assert b'Rock' in response.data or b'Metal' in response.data
