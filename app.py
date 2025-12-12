from flask import Flask, render_template
from config import Config
from models import db, Genre, Band, User
from flask import Flask, render_template, request, redirect, url_for, flash
from flask_login import LoginManager, login_user, logout_user, login_required, current_user
from flask_migrate import Migrate
from functools import wraps



app = Flask(__name__)
app.config.from_object(Config)
app.config.from_object(Config)
app.config['SECRET_KEY'] = 'dev-secret-key-change-in-production'  # We'll make this better in Phase 4


# Initialize database
db.init_app(app)

# Initialize Flask-Migrate
migrate = Migrate(app, db)

login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = 'login'  # Where to redirect if not logged in

# User loader callback
@login_manager.user_loader
def load_user(user_id):
    return User.query.get(int(user_id))

def get_unique_connections(genres):
    """Get unique connections (avoid duplicates)"""
    connections = set()
    for genre in genres:
        if genre.parent:
            # Create connection between genre and its parent
            edge = tuple(sorted([genre.id, genre.parent_id]))
            connections.add(edge)
    return list(connections)

def admin_required(f):
    """Decorator to require admin access"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not current_user.is_authenticated:
            return redirect(url_for('login'))
        if not current_user.is_admin:
            flash('Admin access required.', 'error')
            return redirect(url_for('index'))
        return f(*args, **kwargs)
    return decorated_function

@app.route('/')
def index():
    # Query all genres and bands from database
    genres = Genre.query.all()
    bands = Band.query.all()

    connections = get_unique_connections(genres)

    return render_template('index.html',
                         genres=genres,
                         bands=bands,
                         connections=connections)

@app.route('/add-genre', methods=['GET', 'POST'])
@admin_required
def add_genre():
    if request.method == 'POST':
        # Get form data
        genre_id = request.form['id'].strip()
        name = request.form['name'].strip()
        parent_id = request.form['parent_id'].strip() if request.form['parent_id'] else None
        genre_type = request.form['type']
        # Get selected parent genres (multi-select)
        selected_parent_ids = request.form.getlist('parent_genres')
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
            # Validate primary parent is in selected parents
            if parent_id and selected_parent_ids and parent_id not in selected_parent_ids:
                errors.append("Primary parent must be included in the selected parent genres")
        
        # Validate ID format (only lowercase letters, numbers, hyphens)
        import re
        if genre_id and not re.match(r'^[a-z0-9-]+$', genre_id):
            errors.append("Genre ID can only contain lowercase letters, numbers, and hyphens")
        
        # If there are errors, show them
        if errors:
            for error in errors:
                flash(error, 'error')
            # Re-render form with existing data
            genres = Genre.query.order_by(Genre.name).all()
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

            # Add parent genre relationships
            if selected_parent_ids:
                selected_parents = Genre.query.filter(Genre.id.in_(selected_parent_ids)).all()
                new_genre.parent_genres = selected_parents
            db.session.add(new_genre)
            db.session.commit()
            
            flash(f'Genre "{name}" added successfully!', 'success')
            return redirect(url_for('add_genre'))
            
        except Exception as e:
            db.session.rollback()
            flash(f'Error adding genre: {str(e)}', 'error')
            genres = Genre.query.order_by(Genre.name).all()
            return render_template('add_genre.html',
                                 genres=genres,
                                 form_data=request.form)

    # GET request - show the form
    genres = Genre.query.order_by(Genre.name).all()
    return render_template('add_genre.html', genres=genres)

@app.route('/add-band', methods=['GET', 'POST'])
@admin_required
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
            genres = Genre.query.filter_by(type='leaf').order_by(Genre.name).all()
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
            genres = Genre.query.filter_by(type='leaf').order_by(Genre.name).all()
            return render_template('add_band.html',
                                 genres=genres,
                                 form_data=request.form)

    # GET request - show the form
    # Only show leaf genres (bands can't be assigned to intermediate/root)
    genres = Genre.query.filter_by(type='leaf').order_by(Genre.name).all()
    return render_template('add_band.html', genres=genres)

@app.route('/edit-genre/<genre_id>', methods=['GET', 'POST'])
@admin_required
def edit_genre(genre_id):
    # Get the genre to edit
    genre = Genre.query.get_or_404(genre_id)
    
    if request.method == 'POST':
        # Get form data
        new_name = request.form['name'].strip()
        new_parent_id = request.form['parent_id'].strip() if request.form['parent_id'] else None
        new_type = request.form['type']
        # Get selected parent genres (multi-select)
        selected_parent_ids = request.form.getlist('parent_genres')

        # Validation
        errors = []
        
        if not new_name:
            errors.append("Genre name is required")
        if not new_type:
            errors.append("Genre type is required")
        
        # Check if parent exists (if provided)
        if new_parent_id:
            parent = Genre.query.get(new_parent_id)
            if not parent:
                errors.append(f"Parent genre '{new_parent_id}' does not exist")
            # Prevent circular reference (genre can't be its own parent)
            if new_parent_id == genre_id:
                errors.append("A genre cannot be its own parent")
            # Validate primary parent is in selected parents
            if new_parent_id and selected_parent_ids and new_parent_id not in selected_parent_ids:
                errors.append("Primary parent must be included in the selected parent genres")
            # Prevent circular reference in parent_genres
            if genre_id in selected_parent_ids:
                errors.append("A genre cannot be its own parent")
        
        if errors:
            for error in errors:
                flash(error, 'error')
            genres = Genre.query.filter(Genre.id != genre_id).order_by(Genre.name).all()
            return render_template('edit_genre.html',
                                 genre=genre,
                                 genres=genres,
                                 form_data=request.form)
        
        # Try to update
        try:
            genre.name = new_name
            genre.parent_id = new_parent_id
            genre.type = new_type

            # Update parent genre relationships
            if selected_parent_ids:
                selected_parents = Genre.query.filter(Genre.id.in_(selected_parent_ids)).all()
                genre.parent_genres = selected_parents
            else:
                genre.parent_genres = []
            
            db.session.commit()
            
            flash(f'Genre "{new_name}" updated successfully!', 'success')
            return redirect(url_for('admin'))
            
        except Exception as e:
            db.session.rollback()
            flash(f'Error updating genre: {str(e)}', 'error')
            genres = Genre.query.filter(Genre.id != genre_id).order_by(Genre.name).all()
            return render_template('edit_genre.html',
                                 genre=genre,
                                 genres=genres,
                                 form_data=request.form)

    # GET request - show the form
    genres = Genre.query.filter(Genre.id != genre_id).order_by(Genre.name).all()
    return render_template('edit_genre.html', genre=genre, genres=genres)

@app.route('/edit-band/<band_id>', methods=['GET', 'POST'])
@admin_required
def edit_band(band_id):
    # Get the band to edit
    band = Band.query.get_or_404(band_id)
    
    if request.method == 'POST':
        # Get form data
        new_name = request.form['name'].strip()
        new_primary_genre_id = request.form['primary_genre_id']
        selected_genre_ids = request.form.getlist('genres')
        
        # Validation
        errors = []
        
        if not new_name:
            errors.append("Band name is required")
        if not new_primary_genre_id:
            errors.append("Primary genre is required")
        if not selected_genre_ids:
            errors.append("At least one genre must be selected")
        
        # Check if primary genre exists and is a leaf
        if new_primary_genre_id:
            primary_genre = Genre.query.get(new_primary_genre_id)
            if not primary_genre:
                errors.append(f"Primary genre '{new_primary_genre_id}' does not exist")
            elif primary_genre.type != 'leaf':
                errors.append(f"Primary genre must be a 'leaf' genre. '{primary_genre.name}' is type '{primary_genre.type}'")
        
        # Validate primary genre is in selected genres
        if new_primary_genre_id and selected_genre_ids and new_primary_genre_id not in selected_genre_ids:
            errors.append("Primary genre must be included in the selected genres")
        
        if errors:
            for error in errors:
                flash(error, 'error')
            genres = Genre.query.filter_by(type='leaf').order_by(Genre.name).all()
            return render_template('edit_band.html',
                                 band=band,
                                 genres=genres,
                                 form_data=request.form)
        
        # Try to update
        try:
            band.name = new_name
            band.primary_genre_id = new_primary_genre_id
            
            # Update genre relationships
            selected_genres = Genre.query.filter(Genre.id.in_(selected_genre_ids)).all()
            band.genres = selected_genres
            
            db.session.commit()
            
            flash(f'Band "{new_name}" updated successfully!', 'success')
            return redirect(url_for('admin'))
            
        except Exception as e:
            db.session.rollback()
            flash(f'Error updating band: {str(e)}', 'error')
            genres = Genre.query.filter_by(type='leaf').order_by(Genre.name).all()
            return render_template('edit_band.html',
                                 band=band,
                                 genres=genres,
                                 form_data=request.form)

    # GET request - show the form
    genres = Genre.query.filter_by(type='leaf').order_by(Genre.name).all()
    return render_template('edit_band.html', band=band, genres=genres)

@app.route('/delete-genre/<genre_id>', methods=['POST'])
@admin_required
def delete_genre(genre_id):
    genre = Genre.query.get_or_404(genre_id)
    
    # Safety checks
    errors = []
    
    # Check if genre has children
    children = Genre.query.filter_by(parent_id=genre_id).all()
    if children:
        child_names = ', '.join([c.name for c in children])
        errors.append(f"Cannot delete '{genre.name}' - it has child genres: {child_names}")
    
    # Check if any bands use this as primary genre
    bands_using = Band.query.filter_by(primary_genre_id=genre_id).all()
    if bands_using:
        band_names = ', '.join([b.name for b in bands_using])
        errors.append(f"Cannot delete '{genre.name}' - it's the primary genre for: {band_names}")
    
    if errors:
        for error in errors:
            flash(error, 'error')
        return redirect(request.referrer or url_for('index'))
    
    # Safe to delete
    try:
        db.session.delete(genre)
        db.session.commit()
        flash(f'Genre "{genre.name}" deleted successfully!', 'success')
    except Exception as e:
        db.session.rollback()
        flash(f'Error deleting genre: {str(e)}', 'error')
    
    return redirect(request.referrer or url_for('index'))


@app.route('/delete-band/<band_id>', methods=['POST'])
@admin_required
def delete_band(band_id):
    band = Band.query.get_or_404(band_id)
    
    try:
        db.session.delete(band)
        db.session.commit()
        flash(f'Band "{band.name}" deleted successfully!', 'success')
    except Exception as e:
        db.session.rollback()
        flash(f'Error deleting band: {str(e)}', 'error')
    
    return redirect(request.referrer or url_for('index'))

@app.route('/admin')
@admin_required
def admin():
    genres = Genre.query.order_by(Genre.name).all()
    bands = Band.query.order_by(Band.name).all()
    return render_template('admin.html', genres=genres, bands=bands)

@app.route('/login', methods=['GET', 'POST'])
def login():
    # If already logged in, redirect to home
    if current_user.is_authenticated:
        return redirect(url_for('index'))
    
    if request.method == 'POST':
        username = request.form['username'].strip()
        password = request.form['password']
        
        # Find user by username
        user = User.query.filter_by(username=username).first()
        
        # Check if user exists and password is correct
        if user is None or not user.check_password(password):
            flash('Invalid username or password', 'error')
            return redirect(url_for('login'))
        
        # Log the user in
        login_user(user)
        flash(f'Welcome back, {user.username}!', 'success')
        
        # Redirect to next page or home
        next_page = request.args.get('next')
        if next_page:
            return redirect(next_page)
        return redirect(url_for('index'))
    
    return render_template('login.html')

@app.route('/register', methods=['GET', 'POST'])
def register():
    # If already logged in, redirect to home
    if current_user.is_authenticated:
        return redirect(url_for('index'))
    
    if request.method == 'POST':
        username = request.form['username'].strip()
        email = request.form['email'].strip()
        password = request.form['password']
        password_confirm = request.form['password_confirm']
        
        # Validation
        errors = []
        
        if not username:
            errors.append("Username is required")
        if not email:
            errors.append("Email is required")
        if not password:
            errors.append("Password is required")
        
        # Check password match
        if password != password_confirm:
            errors.append("Passwords do not match")
        
        # Check password length
        if len(password) < 6:
            errors.append("Password must be at least 6 characters")
        
        # Check if username already exists
        if username and User.query.filter_by(username=username).first():
            errors.append(f"Username '{username}' is already taken")
        
        # Check if email already exists
        if email and User.query.filter_by(email=email).first():
            errors.append(f"Email '{email}' is already registered")
        
        if errors:
            for error in errors:
                flash(error, 'error')
            return render_template('register.html', form_data=request.form)
        
        # Create new user
        try:
            new_user = User(
                username=username,
                email=email,
                is_admin=False  # New users are not admins
            )
            new_user.set_password(password)
            
            db.session.add(new_user)
            db.session.commit()
            
            # Log them in automatically
            login_user(new_user)
            
            flash(f'Account created successfully! Welcome, {username}!', 'success')
            return redirect(url_for('index'))
            
        except Exception as e:
            db.session.rollback()
            flash(f'Error creating account: {str(e)}', 'error')
            return render_template('register.html', form_data=request.form)
    
    return render_template('register.html')

@app.route('/logout')
@admin_required
def logout():
    logout_user()
    flash('You have been logged out.', 'success')
    return redirect(url_for('index'))

@app.route('/admin/users')
@admin_required
def manage_users():
    users = User.query.order_by(User.created_at.desc()).all()
    return render_template('manage_users.html', users=users)

@app.route('/admin/users/toggle-admin/<int:user_id>', methods=['POST'])
@admin_required
def toggle_admin(user_id):
    user = User.query.get_or_404(user_id)
    
    # Prevent removing your own admin rights
    if user.id == current_user.id:
        flash('You cannot change your own admin status', 'error')
        return redirect(url_for('manage_users'))
    
    user.is_admin = not user.is_admin
    action = "granted" if user.is_admin else "removed"
    
    try:
        db.session.commit()
        flash(f'Admin rights {action} for {user.username}', 'success')
    except Exception as e:
        db.session.rollback()
        flash(f'Error updating user: {str(e)}', 'error')
    
    return redirect(url_for('manage_users'))

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)