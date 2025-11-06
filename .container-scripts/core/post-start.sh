#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

PROJECT_ROOT="${PROJECT_ROOT:-/workspace}"
CONTAINER_HOME="${CONTAINER_HOME:-${HOME}}"

log() {
    local level="$1"; shift
    printf '[%s] %s\n' "$level" "$*" 1>&2
}

install_pre_commit() {
    if [ ! -f "${PROJECT_ROOT}/.pre-commit-config.yaml" ]; then
        log DEBUG "No .pre-commit-config.yaml found, skipping pre-commit install"
        return
    fi

    if ! command -v uv >/dev/null 2>&1; then
        log WARN "uv not available, cannot install pre-commit hooks"
        return
    fi

    log INFO "Installing pre-commit hooks"
    (cd "${PROJECT_ROOT}" && uv run pre-commit install)
}

start_claude_templates() {
    if ! command -v npx >/dev/null 2>&1; then
        log WARN "npx not available, skipping Claude Code templates"
        return
    fi

    local logs_dir="${CONTAINER_HOME}/workspace/logs"
    mkdir -p "${logs_dir}"

    if pgrep -f "claude-code-templates@latest" >/dev/null 2>&1; then
        log DEBUG "Claude Code templates already running, skipping"
        return
    fi

    log INFO "Starting Claude Code templates (logs at ${logs_dir}/claude-templates.log)"
    nohup npx claude-code-templates@latest --analytics \
        > "${logs_dir}/claude-templates.log" 2>&1 &
}

setup_serena_mcp() {
    if ! command -v claude >/dev/null 2>&1; then
        log WARN "claude CLI not available, skipping MCP server registration"
        return
    fi
    if ! command -v uvx >/dev/null 2>&1; then
        log WARN "uvx not available, skipping MCP server registration"
        return
    fi

    log INFO "Registering Serena MCP server (idempotent)"
    claude mcp add serena -- uvx --from git+https://github.com/oraios/serena serena start-mcp-server \
        --enable-web-dashboard false \
        --context ide-assistant \
        --project "${PROJECT_ROOT}" || true
}

log INFO "Starting core post-start script"

install_pre_commit
start_claude_templates
setup_serena_mcp

log INFO "Core post-start finished"
