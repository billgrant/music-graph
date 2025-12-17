# Music Graph Project - Claude Context

**Last Updated:** December 17, 2025 (Phase 11 In Progress - Cloud SQL Complete)

## Project Overview

Music Graph is a Flask web application that visualizes music genre hierarchies and band relationships as an interactive graph. Built as a learning project with AI-assisted development, documenting the journey through blog posts.

**Live Sites:**
- **Production:** https://music-graph.billgrant.io (PUBLIC!)
- **Development:** https://dev.music-graph.billgrant.io

**Current Version:** v0.3.0-beta (Phase 11 - Cloud SQL)

**Versioning Strategy:**
- Format: `v0.X.Y-beta` where X = phase, Y = fixes within phase
- Phase releases (v0.X.0) are major milestones, kept forever in GCR
- Y increments for changes/fixes before moving to next phase
- Example: Phase 11 = v0.3.0-beta, fixes would be v0.3.1-beta, v0.3.2-beta, etc.

**Tech Stack:**
- Python 3.12 + Flask + Gunicorn
- Cloud SQL PostgreSQL (production/dev) / SQLite (local)
- Docker + docker-compose
- GCP Secret Manager for credentials
- Deployed on Google Cloud Platform (Compute Engine → Cloud Run planned)
- Terraform for infrastructure (with workspaces)
- GitHub Actions for CI/CD
- GitHub for version control
- GitHub Issues for backlog/task tracking (no Jira needed for solo project)

## Current Phase: Phase 11 (In Progress)

**Focus:** Serverless Migration + Security
**Tracking:** [GitHub Issue #25](https://github.com/billgrant/music-graph/issues/25)

**Full Scope (from Issue #25):**
- [x] Move database to managed service (Cloud SQL) ✅ COMPLETE
- [x] Update example env files for Secret Manager
- [x] Document Cloud SQL backup/restore strategy
- [ ] Deploy Flask app to Cloud Run
- [ ] Update Terraform for Cloud Run architecture
- [ ] Update CI/CD pipeline for Cloud Run deployments
- [ ] Decommission current Compute Engine VMs
- [ ] Fix vis.js CVE (#24 - incorporated)
- [ ] Evaluate container base image
- [ ] Add container image scanning to CI/CD
- [ ] Update documentation

**Architecture Change:**
```
Current:  VM → docker-compose → (Flask + PostgreSQL containers)
Future:   Cloud Run → (Flask container) → Cloud SQL
```

### Phase 11 Progress

**Completed (Day 1 - December 16, 2025):**
- ✅ Google provider upgraded to ~> 6.0
- ✅ Explored Terraform ephemeral variables for secrets (learned the pattern)
- ✅ entrypoint.sh updated to fetch DATABASE_URL from Secret Manager
- ✅ docker-compose.dev.yml updated to remove local db service
- ✅ Cloud SQL dev instance provisioned (db-g1-small, ENTERPRISE edition, ~$9/mo)
- ✅ Data migrated from prod PostgreSQL to Cloud SQL dev
- ✅ Tested locally against Cloud SQL (works, but slow from local machine - expected)
- ✅ Pushed changes, CI/CD deploying to dev VM
- ✅ Cleaned up Neon-specific code (app.py search_path listener, debug_neon.py)
- ✅ Dev environment verified working - **fast** (GCP VM → GCP Cloud SQL, same region)

**Completed (Day 2 - December 17, 2025):**
- ✅ Cloud SQL prod instance provisioned
- ✅ Data migrated from prod PostgreSQL container to Cloud SQL prod
- ✅ docker-compose files updated: `network_mode: host` for GCP metadata server access
- ✅ Dockerfile updated: added `curl` for Secret Manager API calls
- ✅ Both dev and prod verified working with Cloud SQL
- ✅ Removed obsolete backup scripts (`backup-database.sh`, `verify-backup-setup.sh`)
- ✅ Updated example env files (removed DATABASE_URL/POSTGRES_PASSWORD - now from Secret Manager)
- ✅ Documented Cloud SQL backup/restore strategy

**Attempted (Neon) - ABANDONED:**
- Tried Neon free tier PostgreSQL
- Cross-cloud latency (GCP → AWS) was unacceptable (~10-20ms per query)
- Empty search_path issue required workarounds (pooler didn't support search_path in options)
- Decision: Use Cloud SQL instead (same GCP region, ~1-2ms latency)

**Key Learnings:**
- Docker containers need `network_mode: host` to access GCP metadata server at `169.254.169.254`
- Container image needs `curl` to call Secret Manager API
- Cloud SQL ENTERPRISE edition required for smaller tiers (db-g1-small)

**Architecture Notes:**
- Cloud SQL handles backups automatically (enabled for prod, 7-day retention, point-in-time recovery)
- No more local PostgreSQL container to manage
- DATABASE_URL fetched from Secret Manager at container startup
- Secret Manager secrets constructed by Terraform from Cloud SQL outputs

**Next Steps (Cloud Run Migration):**
1. Deploy Flask app to Cloud Run
2. Update Terraform for Cloud Run architecture
3. Update CI/CD for Cloud Run deployments
4. Decommission Compute Engine VMs
5. Address vis.js CVE (#24)

**Note:** Packer golden images (#7) no longer needed with serverless approach.

## Previous Phase: Phase 10 (Complete ✅)

**Focus:** UI Enhancements (Issue #21)

**Completed:**
- ✅ Base template pattern - Jinja2 inheritance for DRY templates (#17)
- ✅ Detail panel showing all band/genre relationships (#15)
- ✅ Generic panel renderer (extensible for future entity types)
- ✅ Click-to-toggle panel behavior
- ⏸️ Graph scalability (#16) - deferred pending user feedback

## Previous Phase: Phase 9 (Complete ✅) - GOING PUBLIC!

**Focus:** Minimum viable changes to go public safely

**Completed:**
- ✅ Gunicorn replaces Flask dev server (2 workers)
- ✅ Fixed logout bug (wrong decorator)
- ✅ Hidden login UI, disabled registration
- ✅ Rate limiting on login (5/minute via Flask-Limiter)
- ✅ GCP Secret Manager for SECRET_KEY and POSTGRES_PASSWORD
- ✅ Entrypoint fetches secrets via metadata server (no gcloud dependency)
- ✅ Split firewall variables (web public, SSH restricted)
- ✅ Site is now publicly accessible!

## Previous Phase: Phase 8 (Complete ✅)

**Focus:** UI/UX Improvements Based on User Feedback (Issue #14)

**Completed:**
- ✅ Viewport-relative graph sizing (fills screen)
- ✅ Node sizing by hierarchy (root=large, intermediate=medium, leaf=small)
- ✅ Alphabetically sorted genre lists
- ✅ Client-side search/filter for multi-selects
- ✅ Larger genre selection boxes
- ✅ Fixed footer with contact info
- ✅ Removed dict conversion (Issue #4)
- ✅ Fixed test isolation (tests no longer wipe dev database)

## Previous Phase: Phase 7 (Complete ✅)

**Focus:** CI/CD and DevOps

**Completed:**
- ✅ GitHub Actions for automated testing
- ✅ Separate dev environment with own VM and database
- ✅ Test suite (17 tests, all passing)
- ✅ Code coverage and linting in CI
- ✅ Automated deployment to dev on push to main
- ✅ Manual promotion to production with versioning
- ✅ CI/CD optimization (Issue #8): Path filters, image tagging, GCR lifecycle policy, Docker cleanup
- ✅ Terraform restructure: environments/ and project/ separation
- ✅ Database backup system: Daily automated backups to GCS, 7-day retention, tested restore procedure
- ✅ SSL/Certbot: Switched to Route53 DNS-01 challenge for auto-renewal (no port 80 required)
- ✅ AWS IAM integration: Terraform-managed IAM user/policy for certbot Route53 access

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

## Project Location & Claude Code Access

**IMPORTANT:** Bill starts Claude Code CLI from `~/code` directory to provide access to both repos:
- `~/code/music-graph` - This project (Flask app, Terraform, Docker)
- `~/code/billgrant.github.io` - Blog repo for writing phase documentation

**Claude Code has direct filesystem access** - use Read, Edit, Glob, Grep tools directly on these paths. No need to fetch from GitHub when you can read locally.

**GitHub Repository:** https://github.com/billgrant/music-graph

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

**GitHub Issues (Active Backlog):**
- #1: Production-ready authentication (password reset, 2FA, session management)
- #18: Add Redis backend for rate limiting
- #20: Public registration with enhanced authentication
- #22: Automated dev database sync from production
- #23: CI/CD auto-tag incorrectly uses -alpha instead of -beta (bug)
- #24: Security patching strategy for frontend dependencies
- #26: Kubernetes/Helm deployment package (learning project, low priority)

**Completed/Obsolete:**
- #2: Replace Flask dev server ✅ (done in Phase 9 - Gunicorn)
- #4: Remove dict conversion ✅ (done in Phase 8)
- #7: Packer golden images (obsolete - serverless pivot)

**Future Roadmap:**
- #27: REST API + MCP Server
- #28: Recommendation engine
- #29: Observability (metrics, logs, traces)
- #30: Troubleshooting toolkit container
- #31: Database credential management (rotation, dynamic secrets, or passwordless)

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
- Blog repo: `~/code/billgrant.github.io` (Jekyll site)
- Posts go in `_posts/` directory with format `YYYY-MM-DD-title.md`
- Tag: #music-graph
- Written by Claude with Bill's intro between `*** ***` markers
- Documents successes AND failures
- Bill opens CLI in `~/code` so Claude can access both repos
- When showing Jinja/template code in posts, wrap with `{% raw %}...{% endraw %}` to prevent Jekyll from processing it:
  ```
  {% raw %}
  {{ genre.name }} or {% if condition %}{% endif %}
  {% endraw %}
  ```

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
- **Don't create GitHub issues without adding them to CLAUDE.md** (Known Issues section)
- **Don't close GitHub issues without updating CLAUDE.md** (move to Completed/Obsolete section)

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

## Claude Code CLI Setup

Bill uses Claude Code CLI (not Claude Desktop) started from `~/code` directory. This provides:
- Direct filesystem access to both repos via Read, Edit, Glob, Grep tools
- No MCP servers needed - Claude Code has native file access
- Can read/edit files in both `music-graph/` and `billgrant.github.io/` repos

**Always use local file tools first** before fetching from GitHub URLs.

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
