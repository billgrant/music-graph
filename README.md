# Music Genre Graph

An interactive web application that visualizes music genres and bands as a connected graph. Built as a learning project to explore Python/Flask, web development, databases, containerization, and AI-assisted development.

## Project Vision

Create a visual map showing how music genres relate to each other and which bands belong to which genres. Users can explore genre relationships and discover bands within each style of music.

## Current Phase: Phase 1 - Basic Flask Application (Nearly Complete)

Building a simple proof of concept with hardcoded data and basic visualization.

### Phase 1 Progress
✅ Flask project structure created
✅ Data structures defined (genres and bands dictionaries)
✅ Basic routes and templates working
✅ Card-based display of genres and bands
✅ Graph visualization with Vis.js
✅ Bands added as text nodes with primary genre connections
⬜ Interactive expand/collapse functionality (Phase 1.5 - next)

### Phase 1 Goals
- ~~Set up Flask project structure~~
- ~~Create simple routes~~
- ~~Render hardcoded genre/band data from Python dictionaries~~
- ~~Display a basic graph visualization showing genres and bands~~
- Add interactive expand/collapse functionality (in progress)

## Data Structure (Phase 1)

Using Python dictionaries to represent the initial data:

### Genres
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

**Design decisions:**
- Using slugs (e.g., `"death-metal"`) as keys for easy lookups
- Separate `name` field for proper display formatting
- Bidirectional connections explicitly defined (if A connects to B, B also lists A)
- Explicit connections prevent performance issues when rendering

### Bands
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

**Design decisions:**
- Bands can belong to multiple genres
- Genre references use the same slug format as genre keys

## Visualization Plan (Phase 1)

**Layout:**
- Genres displayed as circles/nodes
- Lines connecting related genres
- Band names displayed near their associated genre(s)

**Multi-genre bands:**
- For Phase 1: Display band name multiple times (once per genre)
- Future phases: Show primary genre only in visualization, full details on click

**Interaction:**
- Phase 1: Static display, no interactivity
- Future phases: Click to drill down, expand/collapse, detail views

**Visual reference:**
```
     [Rock]
      /  \
     /    \
[Death Metal]  [Groove Metal]
    |  \           |
Cannibal  Death   Pantera
Corpse
```

## Technology Stack

**Current (Phase 1):**
- Python 3.x
- Flask
- HTML/CSS templates
- JavaScript visualization library (TBD - researching D3.js, Cytoscape.js, vis.js)

**Future Phases:**
- Database (SQLite → PostgreSQL)
- User authentication
- Docker containerization
- CI/CD with GitHub Actions
- Homelab deployment
- Monitoring (Grafana/ELK)
- REST API

## Roadmap

### Phase 1: Basic Flask Application *(Current)*
- Set up Flask project structure
- Create simple routes
- Render hardcoded genre/band data
- Basic graph visualization

### Phase 2: Database Integration
- Design schema for genres, bands, relationships
- Set up SQLite
- Migrate from dictionary to database queries
- Basic CRUD operations

### Phase 3: Graph Visualization Enhancement
- Improve interactive graph display
- Add zoom/pan functionality
- Better styling and UX

### Phase 4: User Authentication
- Add user accounts
- Login/logout functionality
- Allow authenticated users to suggest additions
- Moderation workflow

### Phase 5: Containerization
- Create Dockerfile
- Set up docker-compose
- Document containerized setup

### Phase 6: API Layer
- Build REST API endpoints
- API documentation
- Versioning strategy

### Phase 7: Homelab Deployment
- Deploy to homelab environment
- Configure networking and reverse proxy
- SSL certificates

### Phase 8: Monitoring
- Grafana dashboards
- ELK stack or similar logging
- Application performance monitoring
- Alerting

### Phase 9: CI/CD Pipeline
- GitHub Actions automation
- Automated testing
- Deployment automation
- Rollback strategies

### Future Possibilities
- Cloud migration (from homelab to CSP if needed)
- Recommendation engine
- Spotify integration
- Advanced graph algorithms
- Mobile-responsive improvements
- Community features

## Development Approach

- **Small iterations:** Each phase is a manageable chunk
- **Documentation:** Blog post per major milestone
- **AI-assisted:** Using Claude and other AI tools as development partners
- **Learning in public:** Documenting successes and failures

## Getting Started

### Prerequisites
- Python 3.12+
- uv (package manager)

### Local Development Setup

1. Clone the repository:
```bash
git clone https://github.com/billgrant/music-graph.git
cd music-graph
```

2. Create virtual environment and install dependencies:
```bash
uv venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
uv pip install flask
```

3. Run the application:
```bash
python app.py
```

4. Visit `http://localhost:5000` in your browser

### Project Structure
```
music-graph/
├── app.py              # Flask application entry point
├── data.py             # Genre and band data structures
├── templates/          # Jinja2 HTML templates
│   └── index.html      # Main page template
├── static/             # CSS, JS, images
│   └── style.css       # Dark theme styling
└── README.md
```

## Blog

This project is documented on my blog at [billgrant.io](https://billgrant.io).

**Project Posts:**
- [Project Introduction](https://billgrant.io/2025/11/24/music-graph-intro/) - Overview and roadmap
- [Getting Flask Running](https://billgrant.io/2025/11/24/flask-setup-post/) - Phase 1: Initial setup
- [Visualizing Genre Connections](https://billgrant.io/2025/11/25/vis-js-blog-post/) - Phase 1: Graph visualization
- [Adding Bands to the Graph](https://billgrant.io/2025/11/26/bands-blog-post/) - Phase 1: Band nodes

Posts are tagged with [#music-graph](https://billgrant.io/tags/#music-graph).

## Roadmap

## Known Issues and Future Refactoring

### Genre Hierarchy vs. Peer Relationships

**Current Issue:**
The data structure treats all genre connections as equal/peer relationships, but the actual domain model is hierarchical:

- **Rock** (top-level genre)
  - **Metal** (sub-genre of Rock, parent of metal sub-genres)
    - **Death Metal** (leaf - bands belong here)
    - **Groove Metal** (leaf - bands belong here)
    - **Thrash Metal** (leaf - bands belong here)

**The Problem:**
- Bands belong to *leaf nodes* (Death Metal, Groove Metal, etc.), not intermediate nodes (Metal, Rock)
- Current `connections` field doesn't distinguish between parent-child (hierarchical) and peer (related) relationships
- As the genre tree grows, this will become harder to manage and visualize correctly

**Current Workaround:**
- Using `connections` to represent hierarchy
- Understanding that some genres (like Metal, Rock) are categories, not actual genres bands belong to
- Bands only connect to leaf-level genres via `primary_genre`

**Planned Refactoring (Phase 2 - Database Integration):**

When moving to a database schema, implement proper hierarchy:

**Option A: Parent/Child with explicit types**
```python
{
    "name": "Metal",
    "parent_id": "rock",
    "type": "intermediate",  # or "parent", "category"
    "level": 1
}

{
    "name": "Groove Metal",
    "parent_id": "metal", 
    "type": "leaf",
    "level": 2
}
```

**Option B: Separate relationship types**
```python
{
    "name": "Groove Metal",
    "parent_genre": "metal",        # Hierarchical relationship
    "related_genres": ["thrash-metal"]  # Peer/influence relationships
}
```

**Database Schema Considerations:**
- `genres` table with `parent_id` for hierarchy
- `genre_relationships` table for peer connections (influences, crossover, etc.)
- Queries to get full tree path, siblings, children
- Validation to prevent bands being assigned to non-leaf genres

This will enable:
- Better visualization (true hierarchical layout in graph)
- Proper categorization and browsing
- Distinction between "Metal" (category) and "Death Metal" (actual genre)
- Related genres outside the hierarchy (e.g., Jazz-Metal fusion)

**Why Not Fix Now:**
- Current dictionary structure works for Phase 1 (proof of concept)
- Database migration is the natural time to restructure
- Keeps focus on getting visualization working first
- Avoids premature optimization

**References:**
- Discussion: [GitHub Issue/Conversation Link TBD]
- Identified: 2025-11-25
- Planned Resolution: Phase 2 (Database Integration)

## License

[MIT](LICENSE)

## Contact

[billgrant](https://github.com/billgrant)
