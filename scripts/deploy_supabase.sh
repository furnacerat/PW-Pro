#!/bin/bash

# Supabase Deployment Script
# Usage: ./scripts/deploy_supabase.sh

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting Supabase Deployment...${NC}"

# 1. Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "Supabase CLI is not installed. Please install it first:"
    echo "brew install supabase/tap/supabase"
    exit 1
fi

# 2. Login check (simplistic)
echo -e "${YELLOW}Ensure you are logged in to Supabase CLI:${NC}"
echo "If not, run: supabase login"
echo "Press Enter to continue..."
read

# 3. Link Project
# Project ID extracted from .env or Config2.plist: lkmazqixrlofyhlrmfuq
PROJECT_REF="lkmazqixrlofyhlrmfuq"
echo -e "${YELLOW}Linking to project $PROJECT_REF...${NC}"
# We provide the password prompt if needed, but usually it works if logged in
# Using --password is not recommended for scripts without secure input, relying on interactive login
supabase link --project-ref "$PROJECT_REF"

# 4. Push Migrations
echo -e "${YELLOW}Pushing local migrations to remote database...${NC}"
supabase db push

echo -e "${GREEN}Deployment Complete!${NC}"
echo "Your local schema in supabase/migrations/ has been applied to the remote project."
