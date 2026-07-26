FROM public.ecr.aws/lambda/nodejs:20

# Amazon Linux 2023 base managed by AWS — matches the documented handoff pattern
# for rootful Podman + WSL2 devcontainers. The CMD (not ENTRYPOINT) base means
# we can run commands without --entrypoint overrides in normal use.
RUN dnf install -y \
        git which findutils \
        gcc-c++ make python3 \
        tar xz bzip2 gzip ca-certificates \
    && dnf clean all

RUN curl -fsSL https://github.com/cli/cli/releases/download/v2.62.0/gh_2.62.0_linux_amd64.tar.gz \
    | tar xz -C /tmp/ \
    && mv /tmp/gh_*/bin/gh /usr/local/bin/ \
    && rm -rf /tmp/gh_*

RUN curl -fsSL https://github.com/BurntSushi/ripgrep/releases/download/13.0.0/ripgrep-13.0.0-x86_64-unknown-linux-musl.tar.gz \
    | tar xz --strip-components=1 -C /usr/local/bin/ --wildcards '*/rg' \
    && chmod +x /usr/local/bin/rg

# watchexec: file watcher for auto-rebuilding PureScript on .purs save
RUN curl -fsSL https://github.com/watchexec/watchexec/releases/download/v1.25.1/watchexec-1.25.1-x86_64-unknown-linux-musl.tar.xz \
    | tar xJ --strip-components=1 -C /usr/local/bin/ --wildcards '*/watchexec' \
    && chmod +x /usr/local/bin/watchexec

# PureScript toolchain. Versions pinned for reproducible builds.
# spago@next tracks the 0.93+ workspace YAML release line.
# concurrently: run spago watcher + vite side-by-side in dev.sh
RUN npm install -g \
        spago@next \
        purescript@0.15.15 \
        purs-tidy \
        purs-backend-es \
        vite@5 \
        esbuild \
        concurrently

# Shell aliases for common commands
RUN echo 'alias sb="spago build"' >> /root/.bashrc \
    && echo 'alias st="spago test -p purs-dagre && spago test -p purs-viz"' >> /root/.bashrc \
    && echo 'alias pb="purs-backend-es build"' >> /root/.bashrc \
    && echo 'alias dev="./scripts/dev.sh"' >> /root/.bashrc \
    && echo 'alias fmt="purs-tidy format-in-place $(find . -name '\''*.purs'\'' -not -path '\''./output*'\'' -not -path '\''./.spago*'\'')"' >> /root/.bashrc

WORKDIR /workspace
