#!/usr/bin/env bash
set -euo pipefail

# Installs Docker Buildx plugin on Ubuntu (WSL-friendly)
# - Adds Docker's official APT repo if missing
# - Installs docker-buildx-plugin
# - Does NOT remove Docker packages

if [[ "${EUID}" -eq 0 ]]; then
  echo "Please run as a normal user (script uses sudo when needed)."
  exit 1
fi

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1"
    exit 1
  }
}

need_cmd sudo
need_cmd curl
need_cmd gpg
need_cmd dpkg

# Detect Ubuntu codename
if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
else
  echo "Cannot read /etc/os-release"
  exit 1
fi

if [[ "${ID:-}" != "ubuntu" ]]; then
  echo "This script is intended for Ubuntu. Detected ID='${ID:-unknown}'."
  echo "It may still work, but I won't pretend it's guaranteed."
fi

CODENAME="${VERSION_CODENAME:-}"
if [[ -z "$CODENAME" ]]; then
  echo "Could not determine Ubuntu codename (VERSION_CODENAME is empty)."
  exit 1
fi

ARCH="$(dpkg --print-architecture)"
KEYRING_DIR="/etc/apt/keyrings"
KEYRING_PATH="${KEYRING_DIR}/docker.gpg"
REPO_LIST="/etc/apt/sources.list.d/docker.list"

echo "Detected: codename=${CODENAME}, arch=${ARCH}"

echo "Installing prerequisites (ca-certificates, curl, gnupg)..."
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gnupg

echo "Ensuring Docker keyring exists..."
sudo install -m 0755 -d "$KEYRING_DIR"

if [[ ! -f "$KEYRING_PATH" ]]; then
  echo "Adding Docker GPG key to ${KEYRING_PATH}..."
  curl -fsSL "https://download.docker.com/linux/ubuntu/gpg" | sudo gpg --dearmor -o "$KEYRING_PATH"
  sudo chmod a+r "$KEYRING_PATH"
else
  echo "Docker GPG key already present at ${KEYRING_PATH}"
fi

echo "Ensuring Docker APT repo is configured..."
REPO_LINE="deb [arch=${ARCH} signed-by=${KEYRING_PATH}] https://download.docker.com/linux/ubuntu ${CODENAME} stable"

if [[ -f "$REPO_LIST" ]] && grep -Fq "download.docker.com/linux/ubuntu" "$REPO_LIST"; then
  echo "Docker repo already present in ${REPO_LIST}"
else
  echo "Writing ${REPO_LIST}..."
  echo "$REPO_LINE" | sudo tee "$REPO_LIST" >/dev/null
fi

echo "Updating APT and installing Buildx plugin..."
sudo apt-get update -y
sudo apt-get install -y docker-buildx-plugin docker-compose-plugin

echo
echo "Verifying Buildx..."
docker buildx version

echo
echo "Optional: create and use a dedicated builder:"
echo "  docker buildx create --name mybuilder --use"
echo "  docker buildx inspect --bootstrap"
echo
echo "Done."

