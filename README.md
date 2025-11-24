# Music Genre Graph

An interactive web application that visualizes music genres and bands as a connected graph. Built as a learning project to explore Python/Flask, web development, databases, containerization, and AI-assisted development.

## Project Vision

Create a visual map showing how music genres relate to each other and which bands belong to which genres. Users can explore genre relationships and discover bands within each style of music.

## Current Phase: Phase 1 - Basic Flask Application

Building a simple proof of concept with hardcoded data and basic visualization.

### Phase 1 Goals
- Set up Flask project structure
- Create simple routes
- Render hardcoded genre/band data from Python dictionaries
- Display a basic graph visualization showing genres and bands

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

*(To be filled in once project structure is created)*

## Blog

This project is documented on my blog at [billgrant.io](https://billgrant.io).

- [Project Introduction](https://billgrant.io) - Overview and roadmap
- *(Future posts will be linked here)*

## License

[MIT](LICENSE)

## Contact

[billgrant](https://github.com/billgrant)
