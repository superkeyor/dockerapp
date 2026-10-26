# =============================================================================
# Base Image
# =============================================================================
# Debian + Miniforge (mamba + conda environments)
# Install steps borrowed from the official (Ubuntu-only) miniforge3 image:
# https://hub.docker.com/_/debian/tags
# https://github.com/conda-forge/miniforge-images/blob/main/ubuntu/Dockerfile
# Use fixed versions (vs. latest) to avoid freq rebuild
FROM debian:trixie-20261020-slim
ARG MINIFORGE_VERSION=26.9.4-0

ENV CONDA_DIR=/opt/conda
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV PATH=${CONDA_DIR}/bin:${PATH}

# tini: PID 1 init (signal forwarding, zombie reaping), as in the official image
RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -y --no-install-recommends wget ca-certificates tini && \
    rm -rf /var/lib/apt/lists/* && \
    wget --no-hsts -q "https://github.com/conda-forge/miniforge/releases/download/${MINIFORGE_VERSION}/Miniforge3-${MINIFORGE_VERSION}-Linux-$(uname -m).sh" -O /tmp/miniforge.sh && \
    bash /tmp/miniforge.sh -b -p ${CONDA_DIR} && \
    rm /tmp/miniforge.sh && \
    find ${CONDA_DIR} -follow -type f \( -name '*.a' -o -name '*.pyc' \) -delete && \
    conda clean -afy

# =============================================================================
# Environment Variables  
# =============================================================================
ARG ENABLE_CRON=false
ENV ENABLE_CRON=$ENABLE_CRON
ENV TZ=America/Chicago
ENV APP_ENV=production

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PIP_ROOT_USER_ACTION=ignore

# =============================================================================
# System Dependencies
# =============================================================================
RUN export DEBIAN_FRONTEND=noninteractive && \
    ln -fs /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo "$TZ" > /etc/timezone && \
    apt-get update && \
    PKGS="tzdata"; [ "$ENABLE_CRON" = "true" ] && PKGS="$PKGS cron"; \
    apt-get install -y --no-install-recommends $PKGS && \
    rm -rf /var/lib/apt/lists/*

# =============================================================================
# Application Setup & Python Package Installation
# =============================================================================
WORKDIR /app
COPY environment.yml .

RUN mamba env create -y -f environment.yml && \
    echo "source activate app" >> ~/.bashrc && \
    mamba clean -afy

ENV PATH=/opt/conda/envs/app/bin:$PATH

# =============================================================================
# Application Files
# =============================================================================
COPY app/ .
COPY start.sh crontab /

RUN if [ "$ENABLE_CRON" = "true" ]; then crontab /crontab; fi

# =============================================================================
# Container Configuration
# =============================================================================
# Expose port for Flask application
EXPOSE 5000
ENTRYPOINT ["tini", "--"]
CMD ["bash", "/start.sh"]
