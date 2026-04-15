# ── Stage 1: binary downloader ─────────────────────────────────────────────
# 在獨立環境下載並解壓所有 CLI binary，不污染 final image
FROM ubuntu:24.04 AS downloader

RUN apt-get update && apt-get install -y curl unzip && rm -rf /var/lib/apt/lists/*

WORKDIR /binaries

# bat v0.26.1
RUN curl -fsSL https://github.com/sharkdp/bat/releases/download/v0.26.1/bat_0.26.1_amd64.deb -o bat.deb \
    && dpkg -x bat.deb bat-pkg \
    && cp bat-pkg/usr/bin/bat .

# fzf v0.71.0
RUN curl -fsSL https://github.com/junegunn/fzf/releases/download/v0.71.0/fzf-0.71.0-linux_amd64.tar.gz \
    | tar -xz fzf

# ripgrep v15.1.0 (rg)
RUN curl -fsSL https://github.com/BurntSushi/ripgrep/releases/download/15.1.0/ripgrep_15.1.0-1_amd64.deb -o rg.deb \
    && dpkg -x rg.deb rg-pkg \
    && cp rg-pkg/usr/bin/rg .

# fd v10.4.2
RUN curl -fsSL https://github.com/sharkdp/fd/releases/download/v10.4.2/fd_10.4.2_amd64.deb -o fd.deb \
    && dpkg -x fd.deb fd-pkg \
    && cp fd-pkg/usr/bin/fd .

# eza v0.23.4
RUN curl -fsSL https://github.com/eza-community/eza/releases/download/v0.23.4/eza_x86_64-unknown-linux-musl.tar.gz \
    | tar -xz

# sd v1.1.0
RUN curl -fsSL https://github.com/chmln/sd/releases/download/v1.1.0/sd-v1.1.0-x86_64-unknown-linux-musl.tar.gz \
    | tar -xz --strip-components=1 --wildcards '*/sd'

# codex rust-v0.120.0
RUN curl -fsSL https://github.com/openai/codex/releases/download/rust-v0.120.0/codex-x86_64-unknown-linux-musl.tar.gz \
    | tar -xz \
    && mv codex-x86_64-unknown-linux-musl codex

# starship latest
RUN curl -fsSL https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-musl.tar.gz \
    | tar -xz

# opencli browser bridge extension
RUN curl -fsSL https://github.com/jackwener/OpenCLI/releases/download/v1.7.2/opencli-extension.zip \
    -o opencli-extension.zip \
    && unzip opencli-extension.zip -d opencli-extension

# ── Stage 2: Python venv builder ───────────────────────────────────────────
# 用與 final 相同的 base image 建 venv，確保 Python binary 路徑一致
FROM ai-agent-dev:latest AS python-builder

USER root
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    python3.12 \
    python3-pip \
    python3.12-venv \
    && rm -rf /var/lib/apt/lists/*

RUN python3.12 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --upgrade pip && pip install openharness-ai graphifyy

# ── Stage 3: final image ────────────────────────────────────────────────────
FROM ai-agent-dev:latest

USER root
ENV DEBIAN_FRONTEND=noninteractive

# Runtime 套件：Python 3.12（Node.js 改由 nvm 以 ubuntu user 安裝）
RUN apt-get update && apt-get install -y \
    python3.12 \
    python3.12-venv \
    curl \
    git \
    gnupg \
    sudo \
    vim \
    jq \
    libnss3 libnspr4 libatk1.0-0t64 libatk-bridge2.0-0t64 \
    libcups2t64 libdrm2 libxkbcommon0 libxcomposite1 \
    libxdamage1 libxrandr2 libgbm1 libpango-1.0-0 \
    libcairo2 libasound2t64 libxshmfence1 \
    && echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && rm -rf /var/lib/apt/lists/*

# CLI tools from downloader stage
COPY --from=downloader /binaries/bat /binaries/fzf /binaries/rg /binaries/fd \
                       /binaries/eza /binaries/sd /binaries/codex /binaries/starship \
                       /usr/local/bin/

# Python venv from builder stage
COPY --chown=ubuntu:ubuntu --from=python-builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# opencli browser bridge extension (install in Chrome on the host)
COPY --chown=ubuntu:ubuntu --from=downloader /binaries/opencli-extension /opt/opencli-extension

# ubuntu user (uid=1000) 目錄結構，與 host user 同 uid 避免 root 權限問題
RUN mkdir -p /home/ubuntu/.openharness \
             /home/ubuntu/.codex \
             /home/ubuntu/workspace \
    && chown -R ubuntu:ubuntu /home/ubuntu

ENV OPENHARNESS_SETTINGS_DIR="/home/ubuntu/.openharness"
ENV HOME="/home/ubuntu"
ENV OPENCLI_CDP_ENDPOINT=ws://127.0.0.1:9222

WORKDIR /home/ubuntu/workspace

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER ubuntu

# 安裝 nvm 並透過 nvm 安裝 Node.js
ENV NVM_DIR="/home/ubuntu/.nvm"
ENV NODE_VERSION="22.14.0"
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash \
    && . "$NVM_DIR/nvm.sh" \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && . "$NVM_DIR/nvm.sh" && npm install -g @jackwener/opencli

# 關鍵：將 nvm 的 bin 目錄加入 PATH，確保 node/npm 隨處可用
ENV PATH="/home/ubuntu/.nvm/versions/node/v$NODE_VERSION/bin:$PATH"

# 修復 opencli undici 版本與 Node 不相容的問題
USER root
RUN cd /usr/lib/node_modules/@jackwener/opencli \
    && rm -rf node_modules/undici \
    && npm install undici@6.21.1 --save --no-package-lock

# 安裝 Chromium（供 opencli Browser Bridge 使用）
RUN npx --yes @puppeteer/browsers install chromium@latest --path /opt/chromium

ENTRYPOINT ["/entrypoint.sh"]
