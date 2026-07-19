#!/usr/bin/env bash
set -Eeuo pipefail

REPO_HOST="repo.corp.local"
REPO_BASE="http://${REPO_HOST}/rpms"
BACKUP_DIR="/etc/yum.repos.d/backup-$(date +%Y%m%d-%H%M%S)"
REPO_FILE="/etc/yum.repos.d/linuxinfra-local.repo"

log() {
  printf '[%s] %s\n' "$(date '+%F %T')" "$*"
}

need_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "Run this script with sudo."
    exit 1
  fi
}

check_repo() {
  log "Checking repo host resolution: ${REPO_HOST}"
  getent hosts "${REPO_HOST}" >/dev/null 2>&1 || {
    echo "ERROR: ${REPO_HOST} does not resolve."
    exit 1
  }

  log "Checking repo web root..."
  curl -fsI "${REPO_BASE}/base/repodata/repomd.xml" >/dev/null 2>&1 || {
    echo "ERROR: ${REPO_BASE}/ is not reachable."
    exit 1
  }
}

backup_repos() {
  log "Backing up existing repo files to ${BACKUP_DIR}"
  mkdir -p "${BACKUP_DIR}"
  shopt -s nullglob
  local repos=(/etc/yum.repos.d/*.repo)
  if (( ${#repos[@]} > 0 )); then
    cp -a /etc/yum.repos.d/*.repo "${BACKUP_DIR}/"
  fi
  shopt -u nullglob
}

disable_public_repos() {
  log "Disabling enabled public repo entries"
  shopt -s nullglob
  for f in /etc/yum.repos.d/*.repo; do
    case "$(basename "$f")" in
      linuxinfra-local.repo)
        continue
        ;;
      *)
        sed -i 's/^enabled=1/enabled=0/g' "$f" || true
        ;;
    esac
  done
  shopt -u nullglob
}

write_repo_file() {
  log "Writing local repo file: ${REPO_FILE}"
  cat > "${REPO_FILE}" <<EOF
[linuxinfra-base]
name=LinuxInfra Base RPMs
baseurl=${REPO_BASE}/base/
enabled=1
gpgcheck=0
priority=1

[linuxinfra-python]
name=LinuxInfra Python RPMs
baseurl=${REPO_BASE}/python/
enabled=1
gpgcheck=0
priority=1

[linuxinfra-squid]
name=LinuxInfra Squid RPMs
baseurl=${REPO_BASE}/squid/
enabled=0
gpgcheck=0
priority=1
EOF
}

refresh_cache() {
  log "Refreshing DNF cache"
  dnf clean all
  dnf makecache
}

verify() {
  log "Repo list:"
  dnf repolist
}

main() {
  need_root
  check_repo
  backup_repos
  disable_public_repos
  write_repo_file
  refresh_cache
  verify
  log "Local repo setup complete."
}

main "$@"
