#!/usr/bin/env bash

# Start cron if enabled (set ARG ENABLE_CRON=true in Dockerfile or via --build-arg)
if [ "$ENABLE_CRON" = "true" ]; then
    cron  # no & needed; cron daemonizes itself
fi

if [ "$APP_ENV" = "development" ]; then
    # flask provides debug, hot reload
    # exec: replace bash so the server receives SIGTERM directly for graceful shutdown
    exec python main.py
else
    # WSGI - Flask
    # add gunicor/wsgi in front of flask
    # gunicorn default to 8000
    # main.py module : app = Flask(__name__) object
    # connection timeout seconds
    exec gunicorn --timeout 60 --bind 0.0.0.0:5000 main:app

    # ASGI - FastAPI
    # exec uvicorn main:app --host 0.0.0.0 --port 80 --timeout-keep-alive 60
fi