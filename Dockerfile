# 1. Use a DEVEL image (essential for the 'nvcc' compiler)
FROM nvidia/cuda:12.4.1-devel-ubuntu22.04

# 2. Basic system setup and Python 3.11
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Added build-essential and fixed the pip installation
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.11 \
    python3.11-dev \
    python3-pip \
    python3-setuptools \
    build-essential \
    curl \
    git && \
    rm -rf /var/lib/apt/lists/*

# Force the system to recognize 'python' and 'pip' commands
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1 && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1

# 3. Use 'python3 -m pip' to ensure we hit the right version
RUN python3 -m pip install --upgrade pip
RUN python3 -m pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
RUN python3 -m pip install --no-cache-dir packaging runpod

# 4. Install Flash Attention
# This is the heavy compilation step
ENV MAX_JOBS=4
RUN python3 -m pip install flash-attn --no-build-isolation

# 5. RunPod App Setup
WORKDIR /app
COPY handler.py .

CMD ["python3", "-u", "handler.py"]