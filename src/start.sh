#!/usr/bin/env bash

# Use libtcmalloc for better memory management
TCMALLOC="$(ldconfig -p | grep -Po "libtcmalloc.so.\d" | head -n 1)"
export LD_PRELOAD="${TCMALLOC}"

echo "runpod-worker-comfy: Starting ComfyUI"

# Serve the API and don't shutdown the container
if [ "$SERVE_API_LOCALLY" == "true" ]; then
    python3 /comfyui/main.py --disable-auto-launch --disable-metadata --listen --fp32-vae &
    python3 -u /rp_handler.py --rp_serve_api --rp_api_host=0.0.0.0
    echo "runpod-worker-comfy: Starting ComfyUI Locally"
else
    python3 /comfyui/main.py --disable-auto-launch --disable-metadata --fp32-vae &
    python3 -u /rp_handler.py
    echo "runpod-worker-comfy: Starting RunPod Handler"
fi