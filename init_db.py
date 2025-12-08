from app import app
from models import db, Genre, Band, User

def init_database():
    """Initialize the database and load initial data"""
    
    with app.app_context():
        # Drop all tables and recreate (careful - this deletes everything!)
        db.drop_all()
        db.create_all()
        
        print("Creating genres...")
        
        # Create genres with hierarchy
        # Root genre
        rock = Genre(id='rock', name='Rock', parent_id=None, type='root')
        
        # Intermediate genre (parent of sub-genres, but not a "real" genre for bands)
        metal = Genre(id='metal', name='Metal', parent_id='rock', type='intermediate')
        metal.parent_genres = [rock]  # Add to many-to-many relationship
        
        # Leaf genres (actual genres bands belong to)
        death_metal = Genre(id='death-metal', name='Death Metal', parent_id='metal', type='leaf')
        death_metal.parent_genres = [metal]
        
        groove_metal = Genre(id='groove-metal', name='Groove Metal', parent_id='metal', type='leaf')
        groove_metal.parent_genres = [metal]
        
        thrash_metal = Genre(id='thrash-metal', name='Thrash Metal', parent_id='metal', type='leaf')
        thrash_metal.parent_genres = [metal]
        
        # Add all genres
        db.session.add_all([rock, metal, death_metal, groove_metal, thrash_metal])
        db.session.commit()
        
        print("Creating bands...")
        
        # Create bands
        pantera = Band(id='pantera', name='Pantera', primary_genre_id='groove-metal')
        pantera.genres = [groove_metal, thrash_metal]  # Full genre list
        
        death = Band(id='death', name='Death', primary_genre_id='death-metal')
        death.genres = [death_metal]
        
        cannibal_corpse = Band(id='cannibalcorpse', name='Cannibal Corpse', primary_genre_id='death-metal')
        cannibal_corpse.genres = [death_metal]
        
        anthrax = Band(id='anthrax', name='Anthrax', primary_genre_id='thrash-metal')
        anthrax.genres = [thrash_metal]
        
        # Add all bands
        db.session.add_all([pantera, death, cannibal_corpse, anthrax])
        db.session.commit()

        print("Creating admin user...")
        
        # Create admin user
        admin = User(
            username='admin',
            email='admin@example.com',
            is_admin=True
        )
        admin.set_password('admin123')  # Change this in production!
        
        db.session.add(admin)
        db.session.commit()
        
        print("Database initialized successfully!")
        print(f"Genres: {Genre.query.count()}")
        print(f"Bands: {Band.query.count()}")
        print(f"Users: {User.query.count()}")
        print("\nAdmin user created:")
        print("  Username: admin")
        print("  Password: admin123")

if __name__ == '__main__':
    init_database()