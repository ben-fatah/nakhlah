FROM python:3.11-slim

WORKDIR /app

# System libs needed by Pillow / torchvision
RUN apt-get update && apt-get install -y --no-install-recommends \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

# Install CPU-only torch from the dedicated index, everything else from PyPI.
# This saves ~550 MB of download compared to the default CUDA wheels.
RUN pip install --upgrade pip && \
    pip install --no-cache-dir \
        torch==2.2.2 \
        torchvision==0.17.2 \
        --index-url https://download.pytorch.org/whl/cpu && \
    pip install --no-cache-dir -r requirements.txt \
        --extra-index-url https://pypi.org/simple

COPY . .

# The model file should be baked into the image during build or mounted as a
# volume. See README for how to place it at /app/models/nakhlah_model.pth
ENV PYTHONUNBUFFERED=1
ENV MODEL_PATH=/app/models/nakhlah_model.pth

EXPOSE 10000

# Healthcheck so Render (and Docker) knows when the service is ready
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:10000/health || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "10000"]