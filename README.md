# Music Genre Graph

An interactive web application that visualizes music genres and bands as a connected graph. Built as a learning project to explore Python/Flask, web development, databases, containerization, and AI-assisted development.

## Project Vision

Create a visual map showing how music genres relate to each other and which bands belong to which genres. Users can explore genre relationships and discover bands within each style of music.

## Current Phase: Phase 9 - Infrastructure Modernization (Planning)

Focus on production-grade infrastructure with remote state, Gunicorn, and immutable deployments.

### Phase 8 Summary (Complete ✅)
Phase 8 implemented UI/UX improvements based on user feedback:
- Viewport-relative graph sizing (fills available screen space)
- Node sizing by hierarchy (root=large, intermediate=medium, leaf=small)
- Alphabetically sorted genre lists in all forms
- Client-side search/filter for multi-select dropdowns
- Larger genre selection boxes (250px min-height)
- Fixed footer with contact/GitHub links
- Removed dict conversion tech debt (Issue #4)
- Fixed test isolation bug (tests no longer wipe dev database)

### Phase 7 Summary (Complete ✅)
Phase 7 implemented production-ready CI/CD and DevOps practices:
- GitHub Actions CI/CD pipeline (automated testing, deployment)
- Separate dev environment (own VM, database, subdomain)
- Path filters and image tagging optimization (Issue #8)
- GCR lifecycle policy for automatic cleanup
- Database backup system (GCS, 7-day retention, tested restore)
- SSL auto-renewal via Route53 DNS-01 challenge
- AWS IAM integration for certbot Route53 access
- Terraform restructure (environments/ and project/ separation)

### Phase 6 Summary (Complete ✅)
Phase 6 added multiple parent genre support:
- Added `genre_parents` association table for many-to-many relationships
- Genres can now have multiple parents (e.g., Grindcore → Metal + Hardcore)
- Primary parent determines graph visualization (clean display)
- All parent relationships stored for metadata and future detail views
- Updated add/edit genre forms with multi-select parent selection
- Migration script to populate existing relationships
- Maintains backward compatibility with existing data

### Phase 5 Summary (Complete ✅)
Phase 5 successfully deployed the application to production on Google Cloud Platform:
- Dockerized application with PostgreSQL database
- Terraform-managed infrastructure (Compute Engine, static IP, firewall)
- Nginx reverse proxy with Let's Encrypt SSL
- IP-restricted access for security
- Production-ready secrets management
- Live at https://music-graph.billgrant.io

### Phase 4 Summary (Complete ✅)
Phase 4 successfully added authentication and authorization:
- User registration and login system
- Secure password hashing with Werkzeug
- Session management with Flask-Login
- Role-based access control (admin vs regular users)
- Protected CRUD routes (admin only)
- Admin user management interface
- CLI script for managing admin status
- Navbar adapts to user role and auth status

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

### Phase 4: User Authentication ✅
**Goal:** Secure the application with user accounts and role-based access

**Completed:**
- ✅ User registration with email and password validation
- ✅ Login/logout functionality with Flask-Login
- ✅ Session management and secure cookies
- ✅ Password hashing with Werkzeug Security (never store plain text)
- ✅ User model with admin flag and timestamps
- ✅ `@admin_required` decorator for protecting routes
- ✅ Role-based access control (admin vs regular users)
- ✅ Admin user management page (promote/demote users)
- ✅ CLI script (`make_admin.py`) for managing admin status
- ✅ Navbar conditionally displays based on authentication and role
- ✅ Protection against users changing their own admin status

**Blog Posts:**
- [User Authentication and Authorization](https://billgrant.io/2025/11/26/phase-4-blog-post/)

**Release:** [v0.3.0-alpha](https://github.com/billgrant/music-graph/releases/tag/v0.3.0-alpha)

### Phase 5: Production Deployment ✅
**Goal:** Deploy to cloud infrastructure and make accessible to users

**Completed:**
- ✅ Terraform infrastructure as code (GCP Compute Engine)
- ✅ Dockerized application with docker-compose
- ✅ PostgreSQL database (migrated from SQLite)
- ✅ Nginx reverse proxy configuration
- ✅ SSL/HTTPS with Let's Encrypt (Certbot)
- ✅ Static IP allocation and DNS configuration
- ✅ IP-restricted firewall rules
- ✅ Environment-based secrets management
- ✅ Database persistence across container restarts
- ✅ Production cleanup (removed debug UI elements)

**Blog Posts:**
- [Production Deployment to GCP](https://billgrant.io/2025/11/26/phase-5-gcp-deployment/)

**Release:** [v0.4.0-alpha](https://github.com/billgrant/music-graph/releases/tag/v0.4.0-alpha)

---

## Technology Stack

**Current:**
- Python 3.12+
- Flask web framework
- SQLAlchemy ORM
- PostgreSQL database (production) / SQLite (development)
- Flask-Login for authentication
- Werkzeug Security for password hashing
- Vis.js for graph visualization
- HTML/CSS/JavaScript frontend
- Docker and docker-compose
- Nginx reverse proxy
- Let's Encrypt SSL certificates
- Google Cloud Platform (Compute Engine)
- Terraform for infrastructure as code

**Current:**
- GitHub Actions for CI/CD and deployments
- Google Cloud Storage for database backups
- AWS Route53 for DNS and certbot DNS-01 validation
- AWS IAM for certbot credentials

**Future Additions:**
- Monitoring (Prometheus/Grafana or Cloud Monitoring)
- Centralized logging
- Cloud SQL managed database
- REST API
- Packer images for immutable infrastructure
- GCP Secret Manager for secrets management

---

## Roadmap

### Phase 9: Infrastructure Modernization
**Goal:** Production-grade infrastructure with immutable deployments

**Planned:**
- Remote Terraform state (GCS backend with locking)
- Replace Flask dev server with Gunicorn (Issue #2)
- Immutable infrastructure with Packer images (Issue #7)
- Remove static secrets from repository (Issue #12)
- Import DNS records to Terraform (Issue #11)
- Evaluate Cloud SQL vs Docker PostgreSQL

**Why:** Reproducible infrastructure, better secrets management, production-ready WSGI server

### Phase 10: Monitoring and Observability
**Goal:** Understand application health and usage

**Planned:**
- Application metrics and dashboards
- Error tracking and alerting
- Usage analytics
- Performance monitoring
- Cost tracking and optimization

**Why:** Know when things break and understand how the app is being used

### Future Enhancements
- Recommendation engine ("If you like X, try Y")
- Spotify integration for audio previews
- Advanced graph algorithms (shortest path between genres)
- Mobile-responsive design improvements
- Community features (voting, discussions, comments)
- Enhanced search and filtering
- Band detail pages with more metadata
- API for external integrations
- Migration to managed database service (Cloud SQL)

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

This creates `music_graph.db`, loads initial data, and creates an admin user:
- Username: `admin`
- Password: `admin123`

**Important:** Change the admin password after first login!

You can create additional admin users with:
```bash
python make_admin.py <username>
```

4. Run the application:
```bash
python app.py
```

5. Visit `http://localhost:5000` in your browser

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

**Phase 4 Posts:**
- [User Authentication and Authorization](https://billgrant.io/2025/11/26/phase-4-blog-post/) - Login and role-based access

**Phase 5 Posts:**
- [Production Deployment to GCP](https://billgrant.io/2025/11/26/phase-5-blog-post/) - Docker, Terraform, SSL, cloud infrastructure

**Phase 6 Posts:**
- [Multiple Parent Genres](https://billgrant.io/2025/12/08/phase-6-multiple-parent-genres/) - Many-to-many parent relationships

**Phase 7 Posts:**
- [CI/CD and Production DevOps](https://billgrant.io/2025/12/11/phase-7-cicd-devops/) - GitHub Actions, database backups, SSL auto-renewal

**Phase 8 Posts:**
- [UI/UX Improvements](https://billgrant.io/2025/12/12/phase-8-ui-ux-improvements/) - Viewport sizing, node hierarchy, filtering, footer

**Workflow Posts:**
- [Upgrading My AI Workflow with MCP](https://billgrant.io/2025/12/07/mcp-setup/) - Model Context Protocol setup for better file access

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