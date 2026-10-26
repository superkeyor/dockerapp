# =============================================================================
# Base Image
# =============================================================================
# Miniforge (Ubuntu + mamba + conda environments)
# https://hub.docker.com/r/condaforge/miniforge3/tags
# Use fixed version (vs. latest) to avoid freq rebuild
FROM condaforge/miniforge3:26.9.4-0

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
CMD ["bash", "/start.sh"]
