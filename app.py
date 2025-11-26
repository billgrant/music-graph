from flask import Flask, render_template
from config import Config
from models import db, Genre, Band

app = Flask(__name__)
app.config.from_object(Config)

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

if __name__ == '__main__':
    app.run(debug=True)