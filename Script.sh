#!/usr/bin/env bash
set -euo pipefail

echo "Photon Run Script"

PROJECT_DIR="${PROJECT_DIR:-$HOME/photon_project}"
VENV_DIR="${VENV_DIR:-$PROJECT_DIR/venv}"

echo "Project dir: $PROJECT_DIR"
echo "Venv dir:    $VENV_DIR"
echo ""

# 1) System packages (Python + Tk + venv + Postgres)
sudo apt update
sudo apt install -y \
  python3.11 \
  python3.11-venv \
  python3.11-distutils \
  python3.11-tk \
  python3-pip \
  postgresql \
  postgresql-contrib

# 2) Start + enable Postgres
sudo systemctl enable postgresql
sudo systemctl restart postgresql

# 3) Create student role + photon DB (idempotent)
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

# 4) Create project folder + venv
mkdir -p "$PROJECT_DIR"

if [ ! -d "$VENV_DIR" ]; then
  python3.11 -m venv "$VENV_DIR"
fi

# 5) Install Python deps into venv
# shellcheck disable=SC1090
source "$VENV_DIR/bin/activate"

python -m pip install --upgrade pip
python -m pip install psycopg2-binary Pillow

deactivate

echo ""
echo "Setup Complete "
echo ""
echo "1) Activate venv:"
echo "   source $VENV_DIR/bin/activate"
echo ""
echo "2) Test DB login:"
echo "   psql -U student -d photon -h 127.0.0.1"
echo ""
echo "3) Run UDP server (terminal 1):"
echo "   python UDP_Server.py"
echo ""
echo "4) Run app (terminal 2), make sure venv is active:"
echo "   python pg-python.py"
echo ""
echo "5) Deactivate when done:"
echo "   deactivate"
