# Music Graph Project - Claude Context

**Last Updated:** December 8, 2025 (Phase 7 - Phases 1 & 2 Complete)

## Project Overview

Music Graph is a Flask web application that visualizes music genre hierarchies and band relationships as an interactive graph. Built as a learning project with AI-assisted development, documenting the journey through blog posts.

**Live Sites:**
- **Production:** https://music-graph.billgrant.io
- **Development:** https://dev.music-graph.billgrant.io

**Tech Stack:**
- Python 3.12 + Flask
- PostgreSQL (production/dev) / SQLite (local)
- Docker + docker-compose
- Deployed on Google Cloud Platform (Compute Engine)
- Terraform for infrastructure (with workspaces)
- GitHub Actions for CI/CD
- GitHub for version control

## Current Phase: Phase 7 (In Progress)

**Focus:** CI/CD and DevOps

**Completed:**
- ✅ GitHub Actions for automated testing
- ✅ Separate dev environment with own VM and database
- ✅ Test suite (17 tests, all passing)
- ✅ Code coverage and linting in CI

**Next:**
- ⏳ Automated deployment to dev on push to main
- ⏳ Manual promotion to production
- ⏳ Database backup strategies
- ⏳ Fix certbot auto-renewal with IP restrictions

**Previous Phase:** Phase 6 (Complete) - Multiple parent genres support

## Key People

**Bill (me):** Developer, documenting this as a learning journey
**Aidan (son):** Primary user, provides feature requests and design input
**Claude:** AI development partner throughout the project

## Project Structure

```
music-graph/
├── app.py              # Flask routes and application logic
├── models.py           # SQLAlchemy database models
├── config.py           # Database configuration (SQLite/PostgreSQL)
├── init_db.py          # Database initialization with sample data
├── migrate_genre_parents.py  # Phase 6 migration script
├── make_admin.py       # CLI tool for managing admin users
├── templates/          # Jinja2 HTML templates
├── static/            # CSS, JavaScript, images
├── terraform/         # GCP infrastructure as code
├── docker-compose.yml          # Local development
├── docker-compose.prod.yml     # Production deployment
├── Dockerfile         # Container definition
└── docs/              # Planning documents and archives
```

## Database Schema

**Genre Model:**
- `id` (PK): slug (e.g., 'death-metal')
- `name`: Display name
- `parent_id` (FK): Primary parent for graph visualization
- `type`: 'root', 'intermediate', or 'leaf'
- `parent_genres`: Many-to-many relationship (all parents)

**Band Model:**
- `id` (PK): slug
- `name`: Display name
- `primary_genre_id` (FK): Primary genre for graph
- `genres`: Many-to-many relationship (all genres)

**User Model:**
- Authentication with Flask-Login
- `is_admin` flag for access control

**Design Pattern:**
Both Bands and Genres use "primary + all" pattern:
- Primary determines graph visualization (clean, uncluttered)
- All relationships stored for metadata and future detail views

## Development Workflow Preferences

**For Refactoring Existing Code:**
- Step-by-step, methodical changes
- Test after each change
- Use feature branches
- Get approval (+1) before applying changes

**For New Features:**
- Can do full-file generation
- Still review before applying
- Test locally before production

**Testing:**
- Always test locally first (SQLite)
- Use feature branches for significant changes
- Deploy to production only after local verification

**Cost Consciousness:**
- Using Claude Pro subscription ($20/month)
- No additional API costs preferred
- Using MCP servers for file access (included in Pro)

## Deployment Process

**Local Development:**
```bash
source .venv/bin/activate
python app.py
# Visit http://localhost:5000
```

**Production Deployment:**
```bash
# SSH to GCP VM
gcloud compute ssh prod-music-graph --zone=us-east1-b

# Pull latest code
cd music-graph
git pull origin main

# Rebuild containers
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d --build

# For database changes, run migrations inside container:
docker-compose -f docker-compose.prod.yml exec web python <migration_script>.py
```

## Known Issues & Technical Debt

**GitHub Issues:**
- #1: Production-ready authentication (password reset, 2FA, session management)
- #2: Replace Flask dev server with production WSGI (Gunicorn/Cloud Run)
- #4: Remove database-to-dict conversion in templates (optimization)

**Future Roadmap Items:**
- Create REST API
- Build custom MCP server for the API (learning exercise)
- Genre/band detail views (click to see all relationships)
- Recommendation engine

## Important Context

**Genre Hierarchy:**
- Root genres (e.g., Rock) - top level
- Intermediate genres (e.g., Metal) - organize sub-genres
- Leaf genres (e.g., Death Metal) - actual genres bands belong to
- Bands can only be assigned to leaf genres

**Multiple Parents (Phase 6):**
- Genres like Grindcore belong to both Metal AND Hardcore
- `parent_id` = primary parent (shown in graph)
- `parent_genres` = all parents (stored for metadata)
- This pattern mirrors how Bands work with multiple genres

**Blog Documentation:**
Each phase gets a blog post at https://billgrant.io
- Tag: #music-graph
- Written by Claude with Bill's intro/edits
- Documents successes AND failures

## Architecture Decisions

**Why PostgreSQL in production:**
- Better concurrency than SQLite
- Proper backups
- Cloud SQL migration path

**Why Docker:**
- Consistent environments (dev/prod)
- Easy deployment
- Dependency isolation

**Why Terraform:**
- Infrastructure as code
- Version controlled infrastructure
- Repeatable deployments

**Why IP-restricted firewall:**
- Basic security during development
- Private use by Aidan
- Will need to change before public launch

## Commands You'll Need

**Local database reset:**
```bash
rm music_graph.db
python init_db.py
```

**Make user admin:**
```bash
python make_admin.py <username>
```

**Create database tables:**
```python
from app import app
from models import db
with app.app_context():
    db.create_all()
```

**Run in production container:**
```bash
docker-compose -f docker-compose.prod.yml exec web python <command>
```

## What NOT to Do

- Don't make database changes without migration scripts
- Don't deploy to production without local testing
- Don't assume Flask dev server is production-ready (it's not)
- Don't forget to rebuild Docker containers after code changes
- Don't commit secrets or passwords to git

## Communication Style

**Bill prefers:**
- Clear explanations with examples
- Step-by-step for refactoring
- Approval gates before applying code changes
- Discussing trade-offs openly
- Methodical testing

**Code Change Workflow (Important!):**
1. **Start with high-level explanation** - Explain concepts and approach BEFORE diving into code
2. **Let Bill ask questions** - This is a learning project, understanding comes first
3. **Discuss trade-offs and alternatives** - Present options, explain pros/cons
4. **Address Bill's concerns** - He often catches important issues (e.g., tag collisions, workspace concerns)
5. **Get explicit approval** - Wait for "yes, let's proceed" before writing code
6. **Then implement** - Write the actual code changes after the plan is clear

**What Bill finds most comfortable (Phase 7, Issue #8 planning session as example):**
- High-level conceptual explanation without code details
- Real-world analogies ("don't bake a new cake if the recipe didn't change")
- Discussion of specific technical concerns (latest tag collision, Terraform state)
- Iterative refinement based on questions
- Clear implementation roadmap before touching files
- This builds understanding and catches issues early

**For new patterns:** Show first example in detail, get understanding, then similar changes can move faster

**Bill's Background:**
- 4 years at HashiCorp as Solutions Engineer (expert in Terraform!)
- Networking and system administration background
- Strong DevOps/infrastructure knowledge
- Building this as a learning project ("jack of all trades, master of none")

**Learning Priorities (Focus Areas):**
1. **JavaScript/vis.js** - Almost nothing known, wants to learn
2. **Python Testing (pytest)** - Knows basics, wants patterns and best practices
3. **Flask** - New to framework, wants to learn patterns
4. **GitHub Actions** - Knows enough to get by, wants more depth (job-related)
5. **Databases** - Admin-level knowledge, wants developer perspective
6. **Terraform/DevOps** - Already expert, trust his judgment here!

**Blog posts should:**
- Have Bill's intro between `*** ***` markers
- Be written by Claude below that
- Document the journey, not just the result
- Include code examples and architecture decisions
- Mention both successes and challenges

## MCP Setup (Current)

Bill has three MCP servers configured in Claude Desktop:
1. GitHub access (music-graph and blog repos)
2. Filesystem access to local music-graph directory
3. Filesystem access to local blog directory

This eliminates copy/paste and enables multi-file operations.

## Questions to Ask

If you're unsure about something:
- "Should I test this locally first?"
- "Do you want step-by-step or full-file generation?"
- "Should this be a GitHub issue for later?"
- "Want to review before I apply changes?"

## Success Criteria

**Phase completion means:**
- Feature works in production
- Blog post published
- README updated
- GitHub issue closed
- Aidan can use it

Ready to build! 🎸
