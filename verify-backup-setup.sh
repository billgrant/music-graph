#!/bin/bash
# Verification script for database backup configuration
# Checks that all required components are properly configured
# Usage: ./verify-backup-setup.sh [dev|prod]

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
checks_passed=0
checks_failed=0
checks_warning=0

# Determine environment
ENV=${1:-unknown}
if [ "$ENV" != "dev" ] && [ "$ENV" != "prod" ]; then
  echo -e "${YELLOW}Warning: No environment specified. Some checks will be skipped.${NC}"
  echo "Usage: $0 [dev|prod]"
  echo ""
fi

echo "=== Database Backup Configuration Verification ==="
echo ""

# Check 1: Backup script exists and is executable
echo -n "Checking backup script... "
if [ -x ~/music-graph/backup-database.sh ]; then
  echo -e "${GREEN}✓ PASS${NC}"
  ((checks_passed++))
else
  echo -e "${RED}✗ FAIL${NC}"
  echo "  Fix: chmod +x ~/music-graph/backup-database.sh"
  ((checks_failed++))
fi

# Check 2: Log file exists and is writable
echo -n "Checking log file permissions... "
if [ -w /var/log/music-graph-backup.log ] 2>/dev/null; then
  echo -e "${GREEN}✓ PASS${NC}"
  ((checks_passed++))
elif [ -w ~/music-graph-backup.log ]; then
  echo -e "${YELLOW}⚠ WARNING${NC}"
  echo "  Using home directory log instead of /var/log/"
  ((checks_warning++))
else
  echo -e "${RED}✗ FAIL${NC}"
  echo "  Fix: sudo touch /var/log/music-graph-backup.log && sudo chown $(whoami):$(whoami) /var/log/music-graph-backup.log"
  ((checks_failed++))
fi

# Check 3: User in docker group
echo -n "Checking docker group membership... "
if groups $(whoami) | grep -q docker; then
  echo -e "${GREEN}✓ PASS${NC}"
  ((checks_passed++))
else
  echo -e "${RED}✗ FAIL${NC}"
  echo "  Fix: sudo usermod -aG docker $(whoami) && logout/login"
  ((checks_failed++))
fi

# Check 4: Docker daemon running
echo -n "Checking docker daemon... "
if docker ps > /dev/null 2>&1; then
  echo -e "${GREEN}✓ PASS${NC}"
  ((checks_passed++))
else
  echo -e "${RED}✗ FAIL${NC}"
  echo "  Docker daemon not accessible. Check docker group or service status."
  ((checks_failed++))
fi

# Check 5: Docker compose file exists (if environment specified)
if [ "$ENV" == "dev" ] || [ "$ENV" == "prod" ]; then
  echo -n "Checking docker-compose file... "
  if [ -f ~/music-graph/docker-compose.${ENV}.yml ]; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((checks_passed++))
  else
    echo -e "${RED}✗ FAIL${NC}"
    echo "  Missing: ~/music-graph/docker-compose.${ENV}.yml"
    ((checks_failed++))
  fi
fi

# Check 6: Database container running (if environment specified)
if [ "$ENV" == "dev" ] || [ "$ENV" == "prod" ]; then
  echo -n "Checking database container... "
  cd ~/music-graph
  if docker-compose -f docker-compose.${ENV}.yml ps db | grep -q "Up"; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((checks_passed++))
  else
    echo -e "${RED}✗ FAIL${NC}"
    echo "  Database container not running"
    ((checks_failed++))
  fi
fi

# Check 7: GCS bucket accessible
echo -n "Checking GCS bucket access... "
if gsutil ls gs://music-graph-backups-music-graph-479719/ > /dev/null 2>&1; then
  echo -e "${GREEN}✓ PASS${NC}"
  ((checks_passed++))
else
  echo -e "${RED}✗ FAIL${NC}"
  echo "  Cannot access GCS bucket. Check service account permissions."
  ((checks_failed++))
fi

# Check 8: Cron job configured
echo -n "Checking cron job... "
if crontab -l 2>/dev/null | grep -q "backup-database.sh"; then
  echo -e "${GREEN}✓ PASS${NC}"
  # Show the cron line
  crontab -l | grep backup-database.sh | sed 's/^/  /'
  ((checks_passed++))
else
  echo -e "${YELLOW}⚠ WARNING${NC}"
  echo "  No cron job found. Backups will not run automatically."
  echo "  Fix: crontab -e and add: 0 3 * * * /home/$(whoami)/music-graph/backup-database.sh ${ENV} >> /var/log/music-graph-backup-cron.log 2>&1"
  ((checks_warning++))
fi

# Check 9: gsutil installed
echo -n "Checking gsutil availability... "
if command -v gsutil > /dev/null 2>&1; then
  echo -e "${GREEN}✓ PASS${NC}"
  ((checks_passed++))
else
  echo -e "${RED}✗ FAIL${NC}"
  echo "  gsutil not found. Install Google Cloud SDK."
  ((checks_failed++))
fi

# Summary
echo ""
echo "=== Summary ==="
echo -e "${GREEN}Passed: $checks_passed${NC}"
if [ $checks_warning -gt 0 ]; then
  echo -e "${YELLOW}Warnings: $checks_warning${NC}"
fi
if [ $checks_failed -gt 0 ]; then
  echo -e "${RED}Failed: $checks_failed${NC}"
fi

echo ""

# Exit code
if [ $checks_failed -gt 0 ]; then
  echo -e "${RED}Configuration incomplete. Fix issues above.${NC}"
  exit 1
elif [ $checks_warning -gt 0 ]; then
  echo -e "${YELLOW}Configuration functional but has warnings.${NC}"
  exit 0
else
  echo -e "${GREEN}All checks passed! Backup system is properly configured.${NC}"
  echo ""
  echo "You can test a backup with:"
  echo "  ./backup-database.sh ${ENV}"
  exit 0
fi
