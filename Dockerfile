# Use Nvidia CUDA base image
FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04 as base

# Prevents prompts from packages asking for user input during installation
ENV DEBIAN_FRONTEND=noninteractive
# Prefer binary wheels over source distributions for faster pip installations
ENV PIP_PREFER_BINARY=1
# Ensures output from python is printed immediately to the terminal without buffering
ENV PYTHONUNBUFFERED=1 

# Install Python, git and other necessary tools
RUN apt-get update && apt-get install -y \
    python3.10 \
    python3-pip \
    git \
    wget \
    libsm6 \
    libxext6 \
    ffmpeg

# Clean up to reduce image size
RUN apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Clone ComfyUI repository
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /comfyui

# Change working directory to ComfyUI
WORKDIR /comfyui

# Install ComfyUI dependencies
RUN pip3 install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 \
    && pip3 install --no-cache-dir xformers==0.0.21 \
    && pip3 install -r requirements.txt

# Install runpod
RUN pip3 install runpod requests

# Download checkpoints/vae/LoRA to include in image
# RUN wget -O models/checkpoints/sd_xl_base_1.0.safetensors https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors
# RUN wget -O models/vae/sdxl_vae.safetensors https://huggingface.co/stabilityai/sdxl-vae/resolve/main/sdxl_vae.safetensors
# RUN wget -O models/vae/sdxl-vae-fp16-fix.safetensors https://huggingface.co/madebyollin/sdxl-vae-fp16-fix/resolve/main/sdxl_vae.safetensors
# RUN wget -O models/loras/xl_more_art-full_v1.safetensors https://civitai.com/api/download/models/152309

# Add models
ADD models/checkpoints/beautifulRealistic_v60.safetensors models/checkpoints/
ADD models/controlnet/control_v11p_sd15_openpose.pth models/controlnet/
ADD models/embeddings/bad_prompt_version2-neg.pt models/embeddings/
ADD models/embeddings/easynegative.safetensors models/embeddings/
ADD models/embeddings/ng_deepnegative_v1_75t.pt models/embeddings/
ADD models/vae/vae-ft-mse-840000-ema-pruned.safetensors models/vae/

# Install custom nodes
RUN git clone https://github.com/ltdrdata/ComfyUI-Manager /comfyui/custom_nodes/ComfyUI-Manager
WORKDIR /comfyui/custom_nodes/ComfyUI-Manager
RUN pip3 install -r requirements.txt


RUN git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack /comfyui/custom_nodes/ComfyUI-Impact-Pack
WORKDIR /comfyui/custom_nodes/ComfyUI-Impact-Pack
RUN pip3 install -r requirements.txt

RUN git clone https://github.com/Fannovel16/comfyui_controlnet_aux /comfyui/custom_nodes/comfyui_controlnet_aux
WORKDIR /comfyui/custom_nodes/comfyui_controlnet_aux
RUN pip3 install -r requirements.txt

RUN git clone https://github.com/cubiq/ComfyUI_IPAdapter_plus /comfyui/custom_nodes/ComfyUI_IPAdapter_plus
WORKDIR /comfyui/custom_nodes/ComfyUI_IPAdapter_plus
RUN pip3 install -r requirements.txt

RUN git clone https://github.com/pythongosssss/ComfyUI-WD14-Tagger /comfyui/custom_nodes/ComfyUI-WD14-Tagger
WORKDIR /comfyui/custom_nodes/ComfyUI-WD14-Tagger
RUN pip3 install -r requirements.txt

# Go back to the root
WORKDIR /

# Add the start and the handler
ADD src/start.sh src/rp_handler.py test_input.json ./
RUN chmod +x /start.sh

# Start the container
CMD /start.sh
