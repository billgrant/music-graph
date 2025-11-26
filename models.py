from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

class Genre(db.Model):
    __tablename__ = 'genres'
    
    id = db.Column(db.String(50), primary_key=True)  # e.g., 'death-metal'
    name = db.Column(db.String(100), nullable=False)  # e.g., 'Death Metal'
    parent_id = db.Column(db.String(50), db.ForeignKey('genres.id'), nullable=True)
    type = db.Column(db.String(20), nullable=False)  # 'root', 'intermediate', 'leaf'
    
    # Relationships
    parent = db.relationship('Genre', remote_side=[id], backref='children')
    bands = db.relationship('Band', back_populates='primary_genre')
    
    def __repr__(self):
        return f'<Genre {self.name}>'

class Band(db.Model):
    __tablename__ = 'bands'
    
    id = db.Column(db.String(50), primary_key=True)  # e.g., 'pantera'
    name = db.Column(db.String(100), nullable=False)  # e.g., 'Pantera'
    primary_genre_id = db.Column(db.String(50), db.ForeignKey('genres.id'), nullable=False)
    
    # Relationships
    primary_genre = db.relationship('Genre', back_populates='bands')
    genres = db.relationship('Genre', secondary='band_genres', backref='all_bands')
    
    def __repr__(self):
        return f'<Band {self.name}>'

# Association table for many-to-many relationship (band can have multiple genres)
band_genres = db.Table('band_genres',
    db.Column('band_id', db.String(50), db.ForeignKey('bands.id'), primary_key=True),
    db.Column('genre_id', db.String(50), db.ForeignKey('genres.id'), primary_key=True)
)