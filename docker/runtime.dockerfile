# Smaller multi-stage Dockerfile for FireAnts runtime use
# Does not provide full dev environment

# =========================
# STAGE 1 — BUILDER
# =========================
FROM nvidia/cuda:12.1.1-devel-ubuntu22.04 AS builder
ENV DEBIAN_FRONTEND=noninteractive
ENV TORCH_CUDA_ARCH_LIST="7.0;7.5;8.0;8.6;8.9;9.0"
ENV MAMBA_ROOT_PREFIX=/opt/conda

RUN apt-get update && apt-get install -y --no-install-recommends \
      curl bzip2 ca-certificates build-essential ninja-build \
 && rm -rf /var/lib/apt/lists/*

# micromamba (static) -> /usr/local/bin/micromamba
RUN curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest \
 | tar -xvj -C /usr/local/bin --strip-components=1 bin/micromamba

# create env (python=3.9), clean caches
RUN micromamba create -y -n fireants -c conda-forge python=3.9 pip && \
    micromamba clean --all --yes

# Run everything inside the env
SHELL ["micromamba", "run", "-n", "fireants", "/bin/bash", "-lc"]
ENV PIP_NO_CACHE_DIR=1

# PyTorch (CUDA 12.1) + build tooling
RUN pip install --upgrade pip setuptools wheel ninja && \
    pip install torch==2.5.1 --index-url https://download.pytorch.org/whl/cu121

WORKDIR /src
COPY . .

# Build wheels, install, clean
# Building fused ops takes some time, but has to be built after torch and fireants to avoid
# ABI mismatches
RUN pip wheel . -w /tmp/wheels && \
    pip wheel ./fused_ops -w /tmp/wheels && \
    pip install /tmp/wheels/* && \
    rm -rf /tmp/wheels

# fix ownership & perms so non-root can read/execute in Apptainer SIF
RUN chown -R root:root /opt/conda && \
    chmod -R a+rX /opt/conda

# =========================
# STAGE 2 — RUNTIME
# =========================
FROM nvidia/cuda:12.1.1-runtime-ubuntu22.04 AS runtime
ENV DEBIAN_FRONTEND=noninteractive

# Copy the whole env (self-contained python + libpython + site-packages)
COPY --from=builder /opt/conda /opt/conda
ENV PATH=/opt/conda/envs/fireants/bin:/opt/conda/bin:$PATH
ENV PYTHONUNBUFFERED=1