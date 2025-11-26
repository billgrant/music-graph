from flask import Flask, render_template
from data import genres, bands

app = Flask(__name__)

@app.route('/')
def index():
    connections = get_unique_connections(genres)
    return render_template('index.html', genres=genres, bands=bands, connections=connections)

def get_unique_connections(genres):
    """Get unique connections (avoid duplicates)"""
    connections = set()
    for genre_id, genre_data in genres.items():
        for connection in genre_data['connections']:
            # Create a tuple with IDs sorted alphabetically
            edge = tuple(sorted([genre_id, connection]))
            connections.add(edge)
    return list(connections)

if __name__ == '__main__':
    app.run(debug=True)