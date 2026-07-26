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

# PureScript toolchain. Versions pinned for reproducible builds.
# spago@next tracks the 0.93+ workspace YAML release line.
RUN npm install -g \
        spago@next \
        purescript@0.15.15 \
        purs-tidy \
        purs-backend-es \
        vite@5 \
        esbuild

WORKDIR /workspace
