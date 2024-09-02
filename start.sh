#!/bin/bash
# start_server.sh
# This script starts the FastAPI server with hot reloading enabled.

echo "Starting FastAPI server with hot reloading..."
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
