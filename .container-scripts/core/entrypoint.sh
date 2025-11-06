#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

PROJECT_ROOT="${PROJECT_ROOT:-/workspace}"
CORE_DIR="${CORE_DIR:-${PROJECT_ROOT}/.container-scripts/core}"
USER_DIR="${USER_DIR:-${PROJECT_ROOT}/.container-scripts/user}"
CONTAINER_HOME="${CONTAINER_HOME:-${HOME}}"

log() {
    local level="$1"; shift
    printf '[%s] %s\n' "$level" "$*" 1>&2
}

sync_container_home() {
    local source_root="${PROJECT_ROOT}/.container-home"
    local target_root="${CONTAINER_HOME}"

    [ -d "${source_root}" ] || return 0

    log INFO "Synchronizing ${source_root} into ${target_root}"

    find "${source_root}" -mindepth 1 -maxdepth 1 -print0 | while IFS= read -r -d '' source_path; do
        local rel_path target_path backup_path
        rel_path="${source_path#"${source_root}/"}"

        case "${rel_path}" in
            .gitkeep) continue ;;
        esac
        target_path="${target_root}/${rel_path}"

        mkdir -p "$(dirname "${target_path}")"

        if [ -L "${target_path}" ]; then
            if [ "$(readlink "${target_path}")" = "${source_path}" ]; then
                continue
            fi
            rm -f "${target_path}"
        elif [ -e "${target_path}" ]; then
            backup_path="${target_path}.bak-$(date +%Y%m%d%H%M%S)"
            log WARN "Backing up existing ${target_path} to ${backup_path}"
            mv "${target_path}" "${backup_path}"
        fi

        ln -s "${source_path}" "${target_path}"
    done
}

run_script_if_present() {
    local script_path="$1"
    local label="$2"

    if [ -x "${script_path}" ]; then
        log INFO "Running ${label}: ${script_path}"
        "${script_path}"
    elif [ -f "${script_path}" ]; then
        log INFO "Marking ${script_path} executable"
        chmod +x "${script_path}"
        log INFO "Running ${label}: ${script_path}"
        "${script_path}"
    else
        log DEBUG "Skipped ${label}, not found: ${script_path}"
    fi
}

log INFO "Container entrypoint start (user: $(whoami))"

sync_container_home

run_script_if_present "${CORE_DIR}/init.sh" "core init"
run_script_if_present "${USER_DIR}/init-add.sh" "user init"

run_script_if_present "${CORE_DIR}/post-start.sh" "core post-start"
run_script_if_present "${USER_DIR}/post-start-add.sh" "user post-start"

log INFO "Entrypoint finished, handing off to container command"
if [ "$#" -gt 0 ]; then
    exec "$@"
else
    exec sleep infinity
fi
