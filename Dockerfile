# 1. Use a DEVEL image (essential for the 'nvcc' compiler)
FROM nvidia/cuda:12.4.1-devel-ubuntu22.04

# 2. Basic system setup and Python 3.11
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.11 python3.11-dev python3-pip curl git && \
    rm -rf /var/lib/apt/lists/*

# Set Python 3.11 as default
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1 && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1

# 3. Install PyTorch FIRST (Matched to CUDA 12.4)
# We also install 'packaging', which flash-attn needs to check versions during build
RUN pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
RUN pip install --no-cache-dir packaging runpod

# 4. Install Flash Attention
# MAX_JOBS limits CPU usage to prevent the build from crashing due to OOM (Out of Memory)
ENV MAX_JOBS=4
RUN pip install flash-attn --no-build-isolation

# 5. RunPod App Setup
WORKDIR /app
COPY handler.py .

CMD ["python", "-u", "handler.py"]
























# FROM nvidia/cuda:12.8.0-cudnn-devel-ubuntu22.04

# WORKDIR /app

# RUN pip install --no-cache-dir runpod
# RUN pip install torch --index-url https://download.pytorch.org/whl/cu124
# RUN pip install -U flash-attn --no-build-isolation

# COPY handler.py .

# CMD ["python", "-u", "handler.py"]