# Music Genre Graph

An interactive web application that visualizes music genres and bands as a connected graph. Built as a learning project to explore Python/Flask, web development, databases, containerization, and AI-assisted development.

## Project Vision

Create a visual map showing how music genres relate to each other and which bands belong to which genres. Users can explore genre relationships and discover bands within each style of music.

## Current Phase: Phase 4 - User Authentication (Starting)

Adding user accounts, login/logout, and protecting CRUD operations.

### Phase 3 Summary (Complete ✅)
Phase 3 successfully added full CRUD operations:
- Web forms for adding genres and bands
- Edit functionality for updating existing data
- Delete operations with safety checks
- Admin panel for viewing and managing all data
- Navigation bar connecting all features
- Validation and error handling throughout
- Flash messages for user feedback

---

## Completed Phases

### Phase 1: Basic Flask Application ✅
**Goal:** Build proof of concept with hardcoded data and graph visualization

**Completed:**
- ✅ Flask project structure created
- ✅ Data structures defined (genres and bands dictionaries)
- ✅ Basic routes and templates working
- ✅ Card-based display of genres and bands
- ✅ Graph visualization with Vis.js
- ✅ Bands added as text nodes with primary genre connections
- ✅ Interactive expand/collapse functionality

**Blog Posts:**
- [Getting Flask Running](https://billgrant.io/2025/11/24/flask-setup-post/)
- [Visualizing Genre Connections](https://billgrant.io/2025/11/25/vis-js-blog-post/)
- [Adding Bands to the Graph](https://billgrant.io/2025/11/26/bands-blog-post/)
- [Interactive Expand/Collapse](https://billgrant.io/2025/11/26/phase-1-5-blog-post/)

**Release:** [v0.0.4-alpha](https://github.com/billgrant/music-graph/releases/tag/v0.0.4-alpha)

### Phase 2: Database Integration ✅
**Goal:** Move from hardcoded dictionaries to proper database

**Completed:**
- ✅ SQLAlchemy ORM integrated
- ✅ Database models created (Genre, Band, relationships)
- ✅ SQLite database configured
- ✅ Genre hierarchy implemented (parent_id, type fields)
- ✅ Data migration from dictionaries to database
- ✅ Flask routes updated to query database
- ✅ All existing functionality preserved

### Phase 3: CRUD Operations ✅
**Goal:** Add ability to manage genres and bands through web interface

**Completed:**
- ✅ Add Genre form with auto-slug generation and validation
- ✅ Add Band form with primary/multi-genre selection
- ✅ Edit Genre functionality
- ✅ Edit Band functionality  
- ✅ Delete Genre with safety checks (prevents deletion if has children or bands)
- ✅ Delete Band functionality
- ✅ Admin panel with table view of all data
- ✅ Navigation bar across all pages
- ✅ Flash messages for success/error feedback
- ✅ Form validation and error handling
- ✅ Form data preservation on validation errors

**Blog Posts:**
- [CRUD Operations and Admin Panel](https://billgrant.io/2025/11/26/phase-3-blog-post/)

**Release:** [v0.2.0-alpha](https://github.com/billgrant/music-graph/releases/tag/v0.2.0-alpha)

---

## Technology Stack

**Current:**
- Python 3.12+
- Flask web framework
- SQLAlchemy ORM
- SQLite database
- Vis.js for graph visualization
- HTML/CSS/JavaScript frontend

**Future Additions:**
- User authentication (Flask-Login or similar)
- PostgreSQL (migration from SQLite)
- Docker containerization
- CI/CD with GitHub Actions
- Monitoring (Grafana/ELK)
- REST API

---

## Roadmap

### Phase 3: CRUD Operations (Next)
**Goal:** Add ability to manage genres and bands through web interface

**Planned:**
- Create forms for adding genres and bands
- Implement edit and delete functionality
- Add validation and error handling
- Simple admin interface for data management

**Why:** Enable adding content without editing code or database directly

### Phase 4: User Authentication
**Goal:** Secure the application with user accounts

**Planned:**
- User registration and login
- Session management
- Protect CRUD operations (must be logged in)
- Basic authorization (who can edit what)
- Consider role-based access (admin vs. contributor)

**Why:** Prepare for multi-user access and prevent unauthorized changes

### Phase 5: Initial Deployment
**Goal:** Deploy to server and make accessible

**Planned:**
- Deploy to homelab environment
- Configure networking and reverse proxy
- Set up SSL certificates
- Make accessible to first user (Aidan)
- Basic production configuration

**Why:** Move from local development to usable application

### Phase 6: Dev/Test/Prod Environments
**Goal:** Separate development from production to prevent breaking live application

**Planned:**
- Dev environment (local development)
- Test/Staging environment (pre-production testing)
- Prod environment (stable version for users)
- Separate databases for each environment
- Deployment workflow/pipeline
- Database migration strategy

**Why:** Once users are actively using the app, we need to develop new features without disrupting production

### Phase 7: Monitoring and Observability
**Goal:** Understand application health and usage

**Planned:**
- Grafana dashboards for application metrics
- ELK stack or similar for logging
- Application performance monitoring
- Alerting for issues
- Usage analytics

**Why:** Know when things break and understand how the app is being used

### Phase 8: CI/CD Pipeline
**Goal:** Automate testing and deployment

**Planned:**
- GitHub Actions workflow
- Automated testing
- Automated deployment to staging/production
- Rollback strategies
- Version tagging automation

**Why:** Reduce manual deployment work and catch issues early

### Future Enhancements
- Recommendation engine ("If you like X, try Y")
- Spotify integration for audio previews
- Advanced graph algorithms (shortest path between genres)
- Mobile-responsive design improvements
- Community features (voting, discussions, comments)
- Search and filtering
- Band detail pages with more metadata
- Cloud migration (if homelab proves insufficient)
- API for external integrations
- Template optimization (use SQLAlchemy objects directly vs. dict conversion)

---

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
uv pip install flask flask-sqlalchemy
```

3. Initialize the database:
```bash
python init_db.py
```

This creates `music_graph.db` and loads initial data.

4. Run the application:
```bash
python app.py
```

5. Visit `http://localhost:5000` in your browser

### Project Structure

```
music-graph/
├── app.py              # Flask application entry point
├── models.py           # SQLAlchemy database models
├── config.py           # Database configuration
├── init_db.py          # Database initialization script
├── music_graph.db      # SQLite database (created by init_db.py)
├── templates/          # Jinja2 HTML templates
│   └── index.html      # Main page template
├── static/             # CSS, JS, images
│   └── style.css       # Dark theme styling
├── docs
│   └── archive
│       ├── PLANNING.md # Original design decisions and Phase 1 planning
│       └── data.py     # Original test data for Phase 1
└── README.md           # This file
```

---

## Development Approach

- **Small iterations:** Each phase is a manageable chunk
- **Documentation:** Blog post per major milestone
- **AI-assisted:** Using Claude and other AI tools as development partners
- **Learning in public:** Documenting successes and failures

---

## Blog

This project is documented on my blog at [billgrant.io](https://billgrant.io).

**Phase 1 Posts:**
- [Project Introduction](https://billgrant.io/2025/11/24/music-graph-intro/) - Overview and roadmap
- [Getting Flask Running](https://billgrant.io/2025/11/24/flask-setup-post/) - Initial setup
- [Visualizing Genre Connections](https://billgrant.io/2025/11/25/vis-js-blog-post/) - Graph visualization
- [Adding Bands to the Graph](https://billgrant.io/2025/11/26/bands-blog-post/) - Band nodes
- [Interactive Expand/Collapse](https://billgrant.io/2025/11/26/phase-1-5-blog-post/) - Phase 1 complete

**Phase 2 Posts:**
- [Database Integration](https://billgrant.io/2025/11/26/phase-2-blog-post/) - SQLAlchemy ORM and hierarchy

**Phase 3 Posts:**
- [CRUD Operations and Admin Panel](https://billgrant.io/2025/11/26/phase-3-blog-post/) - Full data management

All posts are tagged with [#music-graph](https://billgrant.io/tags/#music-graph).
---

## Known Issues and Future Refactoring

### Genre Hierarchy Implementation

**Current State:**
Phase 2 implemented proper genre hierarchy with `parent_id` and `type` fields in the database. Genres can be:
- `root` - top-level genres (e.g., Rock)
- `intermediate` - parent genres that organize sub-genres (e.g., Metal)
- `leaf` - actual genres bands belong to (e.g., Death Metal, Groove Metal)

**Future Enhancement:**
Add support for peer relationships (influences, crossover) separate from hierarchical relationships. This would enable modeling connections like "Jazz-Metal fusion" that don't fit a strict parent-child model.

See [PLANNING.md](docs/archive/PLANNING.md) for original design discussions and evolution of the data model.

### Template Optimization

**Current State:**
Flask routes query database using SQLAlchemy, then convert objects to dictionaries for template compatibility.

**Future Enhancement:**
Update templates to work directly with SQLAlchemy objects, eliminating the conversion step. This is a minor optimization that doesn't affect functionality.

---

## License

[MIT](LICENSE)

## Contact

[billgrant](https://github.com/billgrant)