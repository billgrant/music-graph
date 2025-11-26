# Music Genre Graph - Planning and Design Evolution

This document preserves the original planning, design decisions, and evolution of the music graph project through Phase 1 and Phase 2.

## Table of Contents
- [Original Phase 1 Data Structure](#original-phase-1-data-structure)
- [Original Visualization Plan](#original-visualization-plan)
- [Genre Hierarchy Discussion](#genre-hierarchy-discussion)
- [Design Evolution](#design-evolution)

---

## Original Phase 1 Data Structure

### Initial Dictionary-Based Approach

During Phase 1, data was stored as Python dictionaries before migrating to a database in Phase 2.

**Genres Dictionary:**
```python
genres = {
    "rock": {
        "name": "Rock",
        "connections": ["metal", "punk"]
    },
    "metal": {
        "name": "Metal", 
        "connections": ["rock", "death-metal", "thrash-metal", "groove-metal"]
    },
    "death-metal": {
        "name": "Death Metal",
        "connections": ["metal"]
    },
    "groove-metal": {
        "name": "Groove Metal",
        "connections": ["metal"]
    },
    "thrash-metal": {
        "name": "Thrash Metal",
        "connections": ["metal"]
    }
}
```

**Design Decisions:**
- Using slugs (e.g., `"death-metal"`) as keys for easy lookups
- Separate `name` field for proper display formatting
- Bidirectional connections explicitly defined (if A connects to B, B also lists A)
- Explicit connections prevent performance issues when rendering

**Bands Dictionary:**
```python
bands = {
    "pantera": {
        "name": "Pantera",
        "genres": ["groove-metal", "thrash-metal"]
    },
    "death": {
        "name": "Death",
        "genres": ["death-metal"]        
    },
    "cannibalcorpse": {
        "name": "Cannibal Corpse",
        "genres": ["death-metal"]        
    }
}
```

**Design Decisions:**
- Bands can belong to multiple genres
- Genre references use the same slug format as genre keys

**Evolution to Primary Genre:**

Multi-genre bands initially created visual clutter. Solution: add `primary_genre` field.
```python
"pantera": {
    "name": "Pantera",
    "primary_genre": "groove-metal",  # Used for graph connection
    "genres": ["groove-metal", "thrash-metal"]  # Full list for metadata
}
```

This kept the graph clean while preserving full genre information for future features.

---

## Original Visualization Plan

### Phase 1 Vision

**Layout:**
- Genres displayed as circles/nodes
- Lines connecting related genres
- Band names displayed near their associated genre(s)

**Multi-genre bands:**
- Initial approach: Display band name multiple times (once per genre)
- Revised approach: Show primary genre only in visualization, full details on click

**Interaction:**
- Phase 1.0: Static display, no interactivity
- Phase 1.5: Click to drill down, expand/collapse, detail views

**Visual Reference:**

```
     [Rock]
      /  \
     /    \
[Death Metal]  [Groove Metal]
    |  \           |
Cannibal  Death   Pantera
Corpse
```

### Aidan's Expand/Collapse Vision

My son Aidan envisioned genres as containers:
- Genres visible by default
- Bands hidden until genre is clicked
- Click genre → expand to show bands
- Click again → collapse to hide bands

This approach kept the graph clean and scalable as data grew.

**Implementation (Phase 1.5):**
- Bands have `hidden: true` by default
- JavaScript tracks expanded state
- Click handler toggles visibility
- Only primary genre connection shown in graph

---

## Genre Hierarchy Discussion

**Identified Issue (2025-11-25):**

During Phase 1 development, we realized the data model had a fundamental issue:

The `connections` field treated all relationships as equal/peer connections, but the actual domain model is hierarchical:

- **Rock** (top-level genre)
  - **Metal** (sub-genre of Rock, parent of metal sub-genres)
    - **Death Metal** (leaf - bands belong here)
    - **Groove Metal** (leaf - bands belong here)
    - **Thrash Metal** (leaf - bands belong here)

**The Problem:**
- Bands belong to *leaf nodes* (Death Metal, Groove Metal), not intermediate nodes (Metal, Rock)
- `connections` field doesn't distinguish between parent-child (hierarchical) and peer (related) relationships
- As the genre tree grows, this becomes harder to manage and visualize

**Phase 1 Workaround:**
- Used `connections` to represent hierarchy
- Understood that some genres (Metal, Rock) are categories, not actual genres bands belong to
- Bands only connected to leaf-level genres via `primary_genre`

**Phase 2 Solution:**

Implemented proper hierarchy in database:
```python
class Genre(db.Model):
    id = db.Column(db.String(50), primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    parent_id = db.Column(db.String(50), db.ForeignKey('genres.id'), nullable=True)
    type = db.Column(db.String(20), nullable=False)  # 'root', 'intermediate', 'leaf'
    
    parent = db.relationship('Genre', remote_side=[id], backref='children')
```

**Genre Types:**
- `root` - Top-level genres (Rock, Electronic, etc.)
- `intermediate` - Parent genres organizing sub-genres (Metal)
- `leaf` - Actual genres bands belong to (Death Metal, Groove Metal)

This enables:
- Proper hierarchical queries
- Validation (bands can only be assigned to leaf genres)
- Better visualization options (tree layout, collapsible hierarchy)
- Distinction between categories and actual genres

**Future Enhancement:**

Add peer relationships separate from hierarchy:
```python
# Potential future table
genre_relationships:
    genre_id (FK)
    related_genre_id (FK)
    relationship_type ('influence', 'fusion', 'crossover')
```

This would model relationships like "Jazz-Metal fusion" that don't fit parent-child hierarchy.

---

## Design Evolution

### Phase 1: Proof of Concept
- Started with simple Python dictionaries
- Hardcoded data in `data.py`
- Focused on getting visualization working
- Discovered hierarchy issue but deferred solving it

### Phase 1.5: Interaction
- Added expand/collapse functionality
- Implemented Aidan's vision
- Refined primary genre concept
- Learned JavaScript fundamentals

### Phase 2: Database Migration
- Migrated to SQLAlchemy ORM
- Implemented proper hierarchy with `parent_id` and `type`
- Preserved all Phase 1 functionality
- Set foundation for CRUD operations

### Key Learnings

**What worked well:**
- Small, incremental phases
- Building proof of concept before architecting
- Documenting decisions and issues as they arose
- Using AI assistance for learning new concepts

**What we'd do differently:**
- Could have identified hierarchy issue earlier
- Template conversion (dict → SQLAlchemy objects) could be optimized

**Philosophy:**
- "Make it work, make it right, make it fast" - we're at "make it right"
- Document the journey, including wrong turns
- Perfect is the enemy of shipped

---

## References

**Conversations and Decisions:**
- Genre hierarchy identified: 2025-11-25
- Primary genre concept: Phase 1 development
- Expand/collapse design: Aidan's input, implemented Phase 1.5
- Database schema: Phase 2 planning

**Blog Posts:**
- [Project Introduction](https://billgrant.io/2025/11/24/music-graph-intro/)
- [Getting Flask Running](https://billgrant.io/2025/11/24/flask-setup-post/)
- [Visualizing Genre Connections](https://billgrant.io/2025/11/25/vis-js-blog-post/)
- [Adding Bands](https://billgrant.io/2025/11/26/bands-blog-post/)
- [Expand/Collapse](https://billgrant.io/2025/11/26/phase-1-5-blog-post/)