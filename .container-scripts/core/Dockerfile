FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        dnsutils \
        git \
        iproute2 \
        iptables \
        ipset \
        iputils-ping \
        jq \
        less \
        locales \
        netcat-openbsd \
        nodejs \
        npm \
        python3 \
        python3-pip \
        python3-venv \
        sudo \
        tzdata \
        unzip \
        vim \
        zsh \
    && rm -rf /var/lib/apt/lists/*

RUN if getent group "${USERNAME}" >/dev/null; then \
        groupmod --gid "${USER_GID}" "${USERNAME}"; \
    elif getent group "${USER_GID}" >/dev/null; then \
        existing_group="$(getent group ${USER_GID} | cut -d: -f1)"; \
        groupmod --gid "${USER_GID}" --new-name "${USERNAME}" "${existing_group}"; \
    else \
        groupadd --gid "${USER_GID}" "${USERNAME}"; \
    fi \
    && if id -u "${USERNAME}" >/dev/null 2>&1; then \
        usermod --shell /bin/bash --uid "${USER_UID}" --gid "${USER_GID}" --home /home/${USERNAME} --move-home "${USERNAME}"; \
    elif getent passwd "${USER_UID}" >/dev/null; then \
        existing_user="$(getent passwd ${USER_UID} | cut -d: -f1)"; \
        usermod --login "${USERNAME}" --shell /bin/bash --uid "${USER_UID}" --gid "${USER_GID}" --home /home/${USERNAME} --move-home "${existing_user}"; \
    else \
        useradd --uid "${USER_UID}" --gid "${USER_GID}" -m -s /bin/bash "${USERNAME}"; \
    fi \
    && mkdir -p /home/${USERNAME} \
    && chown -R "${USER_UID}:${USER_GID}" /home/${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

USER "${USERNAME}"
ENV PATH="/home/${USERNAME}/.local/bin:${PATH}" \
    UV_PROJECT_ENVIRONMENT=.venv \
    TZ=UTC

RUN curl -LsSf https://astral.sh/uv/install.sh | sh
# -----------------------------------------------------------------
# !! 警告 !!
# 以下の npm install はすべてグローバル(-g)インストールです。
# パッケージを追加する際は -g を忘れないこと。
# (未来の自分へ: 忘れるなよ！絶対だぞ！)
# RUN npm config set global true  <- AIが提案してきた地雷。絶対ダメ。
# -----------------------------------------------------------------
RUN sudo npm install -g @openai/codex
RUN sudo npm install -g @anthropic-ai/claude-code
RUN sudo npm install -g @google/gemini-cli-core

WORKDIR /workspace
