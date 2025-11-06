#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

PROJECT_ROOT="${PROJECT_ROOT:-/workspace}"
CORE_DIR="${CORE_DIR:-${PROJECT_ROOT}/.container-scripts/core}"
CONTAINER_HOME="${CONTAINER_HOME:-${HOME}}"
WORKSPACE_HOME="${WORKSPACE_HOME:-${CONTAINER_HOME}/workspace}"

log() {
    local level="$1"; shift
    printf '[%s] %s\n' "$level" "$*" 1>&2
}

run_uv_sync() {
    if ! command -v uv >/dev/null 2>&1; then
        log DEBUG "uv not available, skipping dependency sync"
        return
    fi

    if [ -f "${PROJECT_ROOT}/uv.lock" ] || [ -f "${PROJECT_ROOT}/pyproject.toml" ]; then
        log INFO "Running uv sync"
        (cd "${PROJECT_ROOT}" && uv sync)
    else
        log DEBUG "No uv-managed project files detected, skipping uv sync"
    fi
}

configure_git() {
    log INFO "Checking git configuration"
    if [ -z "$(git config --global user.name 2>/dev/null || true)" ]; then
        log WARN "git user.name 未設定。必要なら 'git config --global user.name \"Your Name\"' を実行してください"
    fi
    if [ -z "$(git config --global user.email 2>/dev/null || true)" ]; then
        log WARN "git user.email 未設定。必要なら 'git config --global user.email \"you@example.com\"' を実行してください"
    fi

    git config --global --add safe.directory "${PROJECT_ROOT}/*"
}

append_shell_additions() {
    local additions target_file
    additions="$(cat <<'EOF'

# --- project bootstrap additions ---
git() {
    if [ "$1" = "commit" ]; then
        for arg in "$@"; do
            if [ "$arg" = "--no-verify" ]; then
                echo -e "\033[0;31m❌ ERROR: --no-verify は禁止されています。\033[0m" >&2
                echo "pre-commit を正しく通過させてからコミットしてください。" >&2
                return 1
            fi
        done
    fi
    command git "$@"
}

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias py='uv run python'
alias pip='uv pip'
alias pytest='uv run pytest'
alias ruff='uv run ruff'
alias fw-status='sudo iptables -L -n -v'
EOF
)"

    for target_file in "${CONTAINER_HOME}/.bashrc" "${CONTAINER_HOME}/.zshrc"; do
        if [ -f "${target_file}" ] && ! grep -q "project bootstrap additions" "${target_file}"; then
            log INFO "Appending shell helpers to ${target_file}"
            printf "%s\n" "${additions}" >> "${target_file}"
        fi
    done
}

ensure_directories() {
    log INFO "Ensuring workspace directories exist"
    mkdir -p "${WORKSPACE_HOME}/"{logs,tmp,data,scripts}

    log INFO "Ensuring SSH directory"
    mkdir -p "${CONTAINER_HOME}/.ssh"
    chmod 700 "${CONTAINER_HOME}/.ssh"
}

create_sysinfo_script() {
    local script_path="${WORKSPACE_HOME}/scripts/sysinfo.sh"

    cat > "${script_path}" <<'EOF'
#!/bin/bash
set -euo pipefail

echo "=== System Information ==="
echo "Hostname: $(hostname)"
echo "OS: $(grep PRETTY_NAME /etc/os-release | cut -d= -f2- | tr -d '\"')"
echo "Kernel: $(uname -r)"
echo "Architecture: $(uname -m)"
echo "CPU Cores: $(nproc)"
echo "Memory: $(free -h | awk '/^Mem:/ {print $2}')"
echo "Disk Usage: $(df -h / | awk 'NR==2 {print $3\"/\"$2\" (\"$5\")\"}')"
echo ""
echo "=== Network Configuration ==="
ip addr show | grep -E '(inet |UP)' | grep -v '127.0.0.1'
echo ""
echo "=== Python Environment ==="
command -v python3 && python3 --version
command -v uv && echo "UV Version: $(uv --version)"
EOF

    chmod +x "${script_path}"
}

export_default_envs() {
    for shell_rc in "${CONTAINER_HOME}/.bashrc" "${CONTAINER_HOME}/.zshrc"; do
        [ -f "${shell_rc}" ] || continue
        if ! grep -q "CLAUDE_CODE_AUTO_UPDATE" "${shell_rc}"; then
            echo "export CLAUDE_CODE_AUTO_UPDATE=0" >> "${shell_rc}"
        fi
        if ! grep -q "DISABLE_INTERLEAVED_THINKING" "${shell_rc}"; then
            echo "export DISABLE_INTERLEAVED_THINKING=1" >> "${shell_rc}"
        fi
    done
}

log INFO "Starting core init script"

run_uv_sync
configure_git
append_shell_additions
ensure_directories
create_sysinfo_script
export_default_envs

log INFO "Core init finished"
