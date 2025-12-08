"""
Migration script to populate genre_parents table with existing parent_id relationships.
Run this ONCE after updating models.py and before using the new multi-parent feature.
"""

from app import app
from models import db, Genre

def migrate_genre_parents():
    """Populate genre_parents table with existing parent_id values"""
    
    with app.app_context():
        print("Starting migration: populating genre_parents table...")
        
        # Get all genres that have a parent_id
        genres_with_parents = Genre.query.filter(Genre.parent_id.isnot(None)).all()
        
        print(f"Found {len(genres_with_parents)} genres with parent_id set")
        
        migrated = 0
        for genre in genres_with_parents:
            # Get the parent genre object
            parent = Genre.query.get(genre.parent_id)
            
            if parent:
                # Check if relationship already exists
                if parent not in genre.parent_genres:
                    # Add parent to parent_genres relationship
                    genre.parent_genres.append(parent)
                    print(f"  ✓ Added {parent.name} as parent of {genre.name}")
                    migrated += 1
                else:
                    print(f"  - {parent.name} already in parent_genres for {genre.name}")
            else:
                print(f"  ✗ Warning: Parent '{genre.parent_id}' not found for genre '{genre.name}'")
        
        # Commit all changes
        if migrated > 0:
            db.session.commit()
            print(f"\n✓ Migration complete! Migrated {migrated} parent relationships.")
        else:
            print("\n- No changes needed. All parent relationships already exist in genre_parents.")
        
        # Verify migration
        print("\nVerifying migration...")
        for genre in genres_with_parents:
            parent_count = len(genre.parent_genres)
            if parent_count == 0:
                print(f"  ✗ {genre.name} has parent_id but no parent_genres!")
            elif parent_count == 1:
                print(f"  ✓ {genre.name} → {genre.parent_genres[0].name}")
            else:
                parent_names = ", ".join([p.name for p in genre.parent_genres])
                print(f"  ✓ {genre.name} → [{parent_names}]")

if __name__ == '__main__':
    print("=" * 60)
    print("Genre Parents Migration Script")
    print("=" * 60)
    print("\nThis script will:")
    print("1. Find all genres with a parent_id")
    print("2. Add that parent to the genre_parents many-to-many relationship")
    print("3. Preserve all existing data")
    print("\n" + "=" * 60)
    
    response = input("\nProceed with migration? (yes/no): ")
    
    if response.lower() in ['yes', 'y']:
        migrate_genre_parents()
    else:
        print("Migration cancelled.")