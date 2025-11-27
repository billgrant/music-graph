from flask import Flask, render_template
from config import Config
from models import db, Genre, Band
from flask import Flask, render_template, request, redirect, url_for, flash


app = Flask(__name__)
app.config.from_object(Config)
app.config.from_object(Config)
app.config['SECRET_KEY'] = 'dev-secret-key-change-in-production'  # We'll make this better in Phase 4


# Initialize database
db.init_app(app)

def get_unique_connections(genres):
    """Get unique connections (avoid duplicates)"""
    connections = set()
    for genre in genres:
        if genre.parent:
            # Create connection between genre and its parent
            edge = tuple(sorted([genre.id, genre.parent_id]))
            connections.add(edge)
    return list(connections)

@app.route('/')
def index():
    # Query all genres and bands from database
    genres = Genre.query.all()
    bands = Band.query.all()
    
    # Convert to dict format for template (temporary - we'll improve this later)
    genres_dict = {g.id: {'name': g.name} for g in genres}
    bands_dict = {
        b.id: {
            'name': b.name,
            'primary_genre': b.primary_genre_id,
            'genres': [g.id for g in b.genres]
        } 
        for b in bands
    }

    connections = get_unique_connections(genres)
    
    return render_template('index.html', 
                         genres=genres_dict, 
                         bands=bands_dict, 
                         connections=connections)

@app.route('/add-genre', methods=['GET', 'POST'])
def add_genre():
    if request.method == 'POST':
        # Get form data
        genre_id = request.form['id'].strip()
        name = request.form['name'].strip()
        parent_id = request.form['parent_id'].strip() if request.form['parent_id'] else None
        genre_type = request.form['type']
        
        # Validation
        errors = []
        
        # Check required fields
        if not genre_id:
            errors.append("Genre ID is required")
        if not name:
            errors.append("Genre name is required")
        if not genre_type:
            errors.append("Genre type is required")
        
        # Check if ID already exists
        if genre_id and Genre.query.get(genre_id):
            errors.append(f"Genre ID '{genre_id}' already exists")
        
        # Check if parent exists (if provided)
        if parent_id:
            parent = Genre.query.get(parent_id)
            if not parent:
                errors.append(f"Parent genre '{parent_id}' does not exist")
        
        # Validate ID format (only lowercase letters, numbers, hyphens)
        import re
        if genre_id and not re.match(r'^[a-z0-9-]+$', genre_id):
            errors.append("Genre ID can only contain lowercase letters, numbers, and hyphens")
        
        # If there are errors, show them
        if errors:
            for error in errors:
                flash(error, 'error')
            # Re-render form with existing data
            genres = Genre.query.all()
            return render_template('add_genre.html', 
                                 genres=genres,
                                 form_data=request.form)
        
        # Try to add to database
        try:
            new_genre = Genre(
                id=genre_id,
                name=name,
                parent_id=parent_id,
                type=genre_type
            )
            
            db.session.add(new_genre)
            db.session.commit()
            
            flash(f'Genre "{name}" added successfully!', 'success')
            return redirect(url_for('add_genre'))
            
        except Exception as e:
            db.session.rollback()
            flash(f'Error adding genre: {str(e)}', 'error')
            genres = Genre.query.all()
            return render_template('add_genre.html', 
                                 genres=genres,
                                 form_data=request.form)
    
    # GET request - show the form
    genres = Genre.query.all()
    return render_template('add_genre.html', genres=genres)

@app.route('/add-band', methods=['GET', 'POST'])
def add_band():
    if request.method == 'POST':
        # Get form data
        band_id = request.form['id'].strip()
        name = request.form['name'].strip()
        primary_genre_id = request.form['primary_genre_id']
        
        # Get selected genres (multi-select)
        selected_genre_ids = request.form.getlist('genres')
        
        # Validation
        errors = []
        
        # Check required fields
        if not band_id:
            errors.append("Band ID is required")
        if not name:
            errors.append("Band name is required")
        if not primary_genre_id:
            errors.append("Primary genre is required")
        if not selected_genre_ids:
            errors.append("At least one genre must be selected")
        
        # Check if ID already exists
        if band_id and Band.query.get(band_id):
            errors.append(f"Band ID '{band_id}' already exists")
        
        # Check if primary genre exists and is a leaf
        if primary_genre_id:
            primary_genre = Genre.query.get(primary_genre_id)
            if not primary_genre:
                errors.append(f"Primary genre '{primary_genre_id}' does not exist")
            elif primary_genre.type != 'leaf':
                errors.append(f"Primary genre must be a 'leaf' genre. '{primary_genre.name}' is type '{primary_genre.type}'")
        
        # Validate primary genre is in selected genres
        if primary_genre_id and selected_genre_ids and primary_genre_id not in selected_genre_ids:
            errors.append("Primary genre must be included in the selected genres")
        
        # Validate ID format
        import re
        if band_id and not re.match(r'^[a-z0-9-]+$', band_id):
            errors.append("Band ID can only contain lowercase letters, numbers, and hyphens")
        
        # If errors, show them
        if errors:
            for error in errors:
                flash(error, 'error')
            genres = Genre.query.filter_by(type='leaf').all()
            return render_template('add_band.html', 
                                 genres=genres,
                                 form_data=request.form)
        
        # Try to add to database
        try:
            # Create band
            new_band = Band(
                id=band_id,
                name=name,
                primary_genre_id=primary_genre_id
            )
            
            # Add genre relationships
            selected_genres = Genre.query.filter(Genre.id.in_(selected_genre_ids)).all()
            new_band.genres = selected_genres
            
            db.session.add(new_band)
            db.session.commit()
            
            flash(f'Band "{name}" added successfully!', 'success')
            return redirect(url_for('add_band'))
            
        except Exception as e:
            db.session.rollback()
            flash(f'Error adding band: {str(e)}', 'error')
            genres = Genre.query.filter_by(type='leaf').all()
            return render_template('add_band.html', 
                                 genres=genres,
                                 form_data=request.form)
    
    # GET request - show the form
    # Only show leaf genres (bands can't be assigned to intermediate/root)
    genres = Genre.query.filter_by(type='leaf').all()
    return render_template('add_band.html', genres=genres)

if __name__ == '__main__':
    app.run(debug=True)