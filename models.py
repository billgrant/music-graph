from flask_sqlalchemy import SQLAlchemy
from flask_login import UserMixin
from werkzeug.security import generate_password_hash, check_password_hash

db = SQLAlchemy()

# Association table for many-to-many genre parent relationships
genre_parents = db.Table('genre_parents',
    db.Column('genre_id', db.String(50), db.ForeignKey('genres.id'), primary_key=True),
    db.Column('parent_genre_id', db.String(50), db.ForeignKey('genres.id'), primary_key=True)
)

class Genre(db.Model):
    __tablename__ = 'genres'
    
    id = db.Column(db.String(50), primary_key=True)  # e.g., 'death-metal'
    name = db.Column(db.String(100), nullable=False)  # e.g., 'Death Metal'
    parent_id = db.Column(db.String(50), db.ForeignKey('genres.id'), nullable=True)
    type = db.Column(db.String(20), nullable=False)  # 'root', 'intermediate', 'leaf'
    
    # Relationships
    parent = db.relationship('Genre', remote_side=[id], backref='children')
    # Many-to-many for all parent genres
    parent_genres = db.relationship(
        'Genre',
        secondary=genre_parents,
        primaryjoin=(id == genre_parents.c.genre_id),
        secondaryjoin=(id == genre_parents.c.parent_genre_id),
        backref='child_genres'
    )
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

class User(UserMixin, db.Model):
    __tablename__ = 'users'
    
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    is_admin = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=db.func.now())
    
    def __repr__(self):
        return f'<User {self.username}>'
    
    def set_password(self, password):
        """Hash and store password"""
        self.password_hash = generate_password_hash(password)
    
    def check_password(self, password):
        """Verify password against hash"""
        return check_password_hash(self.password_hash, password)