# Use a base image with PyTorch 2.8.0 and CUDA 12.8
FROM pytorch/pytorch:2.4.0-cuda12.4-cudnn9-runtime

# Set environment variables for non-interactive installs and HF speed
ENV DEBIAN_FRONTEND=noninteractive
ENV HF_HUB_ENABLE_HF_TRANSFER=1
ENV TRANSFORMERS_NO_FLASH_ATTN=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    sox \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /workspace

# Install Qwen3-TTS and its dependencies
RUN git clone https://github.com/QwenLM/Qwen3-TTS.git && \
    cd Qwen3-TTS && \
    pip install -e .

# Install additional Python requirements from your script
RUN pip install --no-cache-dir \
    torch \
    torchaudio \
    soundfile \
    librosa \
    accelerate \
    runpod \
    hf_transfer

# 3. Use the latest transformers to ensure SDPA compatibility
RUN pip install --upgrade transformers

# Add these lines BEFORE the pip install flash-attn command
# ENV MAX_JOBS=1
# ENV NVCC_THREADS=1

# # Install Flash Attention 2 (Optimized for RTX 4090/Ada cards)
# RUN pip install -U flash-attn --no-build-isolation

# Clone your specific implementation
RUN git clone https://github.com/ilikekeyboards4924/qwen3_tts.git /workspace/qwen3_tts

# Create directories for voice cloning
RUN mkdir -p /workspace/voice_clone/embedding /workspace/voice_clone/output

# Set the working directory to your app
WORKDIR /workspace/qwen3_tts

RUN pip uninstall -y flash-attn

# Run your main script (or handler.py if switching to Serverless)
CMD ["python", "-u", "main.py"]