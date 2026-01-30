# Use a lightweight Python base image
FROM python:3.11-slim

# Set the working directory
WORKDIR /app

# Install only the necessary RunPod library
RUN pip install --no-cache-dir runpod
RUN pip install -U flash-attn --no-build-isolation

# Copy your handler.py into the container
COPY handler.py .

# Run the handler with unbuffered output (so logs appear instantly)
CMD ["python", "-u", "handler.py"]