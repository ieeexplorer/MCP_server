#!/usr/bin/env bash
set -Eeuo pipefail

# -----------------------------------------------------------------------------
# Package lists
# -----------------------------------------------------------------------------
APT_PACKAGES=(
  python3
  python3-apt
  python3-venv
  python3-distutils
  python3-pip
  curl
  gnupg
  lsb-release
  software-properties-common
)

OLD_NODE_PACKAGES=(
  nodejs
  nodejs-doc
  libnode72
)

# -----------------------------------------------------------------------------
# Helper functions
# -----------------------------------------------------------------------------
print_status() {
  printf '%s\n' "$1"
}

print_item() {
  printf '   • %-7s → %s\n' "$1" "$2"
}

handle_error() {
  local exit_code=$?
  local line_no=$1
  echo "❌  Setup failed on line ${line_no} with exit code ${exit_code}."
  exit "$exit_code"
}

trap 'handle_error $LINENO' ERR

# -----------------------------------------------------------------------------
# System update and Python tooling
# -----------------------------------------------------------------------------
print_status "🔄  Updating APT package index..."
sudo apt-get update

print_status "🐍  Installing Python support packages and essential tools..."
sudo apt-get install -y "${APT_PACKAGES[@]}"

print_status "✅  Verifying Python installation..."
print_item "python3" "$(python3 --version)"
print_item "pip3" "$(pip3 --version)"

# -----------------------------------------------------------------------------
# Remove older Node.js packages that may cause conflicts
# -----------------------------------------------------------------------------
print_status "🧹  Removing older Node.js packages that may conflict..."
sudo apt-get remove -y "${OLD_NODE_PACKAGES[@]}" || true
sudo apt-get autoremove -y

# -----------------------------------------------------------------------------
# Install Node.js 18.x from NodeSource
# -----------------------------------------------------------------------------
print_status "🔧  Configuring the NodeSource repository for Node.js 18.x..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -

print_status "📦  Installing Node.js, npm, and npx..."
sudo apt-get update
sudo apt-get install -y nodejs

print_status "✅  Verifying Node.js installation..."
print_item "node" "$(node --version)"
print_item "npm"  "$(npm --version)"
print_item "npx"  "$(npx --version)"

# -----------------------------------------------------------------------------
# Create and activate the Python virtual environment
# -----------------------------------------------------------------------------
if [ -d ".venv" ]; then
  print_status "⚠️   Virtual environment (.venv) already exists; skipping creation."
else
  print_status "🐍  Creating the Python virtual environment (.venv)..."
  python3 -m venv .venv
fi

print_status "🔐  Activating the virtual environment..."
# shellcheck disable=SC1091
source ".venv/bin/activate"

print_status "⬆️   Upgrading pip inside the virtual environment..."
pip install --upgrade pip

# -----------------------------------------------------------------------------
# Install Python dependencies if requirements.txt exists
# -----------------------------------------------------------------------------
if [ -f "requirements.txt" ]; then
  print_status "📚  Installing Python dependencies from requirements.txt..."
  pip install -r requirements.txt
else
  print_status "📄  No requirements.txt file found; skipping dependency installation."
fi

# -----------------------------------------------------------------------------
# Final summary
# -----------------------------------------------------------------------------
print_status "🎉  Setup completed successfully!"
echo "   • Inside .venv: $(python --version), pip $(pip --version)"
echo "   • Outside venv: python3 $(python3 --version), pip3 $(pip3 --version)"
echo "   • Node.js: node $(node --version), npm $(npm --version), npx $(npx --version)"
