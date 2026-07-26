FROM public.ecr.aws/lambda/nodejs:20

# Amazon Linux 2023 base managed by AWS — matches the documented handoff pattern
# for rootful Podman + WSL2 devcontainers. The CMD (not ENTRYPOINT) base means
# we can run commands without --entrypoint overrides in normal use.
RUN dnf install -y \
        git gh curl which findutils ripgrep \
        gcc-c++ make \
        tar xz bzip2 gzip ca-certificates \
    && dnf clean all

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
