#!/usr/bin/env bash
set -euo pipefail

echo "=== Photon VM Setup (Debian) ==="

# 1) Update + install packages
sudo apt update
sudo apt install -y python3 python3-pip postgresql postgresql-contrib

# 2) Start + enable postgres
sudo systemctl enable postgresql
sudo systemctl restart postgresql

# 3) Create student role + photon DB (idempotent)
# We run SQL that:
# - creates role student if missing
# - ensures password is set
# - grants createdb
# - creates database photon owned by student if missing
sudo -u postgres psql -v ON_ERROR_STOP=1 <<'SQL'
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'student') THEN
    CREATE ROLE student WITH LOGIN PASSWORD 'student';
  END IF;
END $$;

ALTER ROLE student WITH PASSWORD 'student';
ALTER ROLE student CREATEDB;

DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_database WHERE datname = 'photon') THEN
    CREATE DATABASE photon OWNER student;
  END IF;
END $$;
SQL

# 4) Install psycopg2 driver
python3 -m pip install --upgrade pip
python3 -m pip install psycopg2-binary

echo ""
echo "=== Done! Quick tests ==="
echo "1) Test Postgres login:"
echo "   psql -U student -d photon -h 127.0.0.1"
echo ""
echo "2) Run your UDP server in one terminal:"
echo "   python3 UDP_Server.py"
echo ""
echo "3) Run your DB+UDP app in another terminal:"
echo "   python3 pg-python.py"
echo ""

