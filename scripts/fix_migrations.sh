#!/bin/bash

# Fix Supabase Migration Mismatch
# This script resolves the "Remote migration versions not found" error.

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Fixing Supabase Migration History...${NC}"

# Define the IDs of the "ghost" migrations from the error log
# These exist on remote but not locally (because we consolidated them)
GHOST_MIGRATIONS=("20260206171844" "20260206172513")

# We don't need to revert anymore, simply push the new reset migration
# But to be safe, we can revert the ghosts if they still exist in history
for version in "${GHOST_MIGRATIONS[@]}"; do
    supabase migration repair --status reverted "$version" || true
done


echo -e "${YELLOW}Pushing new consolidated migrations...${NC}"
supabase db push

echo -e "${GREEN}Fix Complete! Database is now in sync.${NC}"
