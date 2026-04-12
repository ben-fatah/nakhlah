FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

# CPU-only torch — ~250 MB instead of ~800 MB
RUN pip install --upgrade pip && \
    pip install --no-cache-dir \
        torch==2.2.2 \
        torchvision==0.17.2 \
        --index-url https://download.pytorch.org/whl/cpu && \
    pip install --no-cache-dir -r requirements.txt

COPY . .

# ── Download model weights at build time ────────────────────────────────────
# Replace the URL below with your actual Hugging Face / Google Drive link.
# The file lands at /app/models/nakhlah_model.pth inside the container.
# Build arg lets you override the URL without editing this file:
#   docker build --build-arg MODEL_URL=https://... .
ARG MODEL_URL
RUN mkdir -p /app/models && \
    if [ -n "$MODEL_URL" ]; then \
        echo "Downloading model from $MODEL_URL ..." && \
        wget -q --show-progress -O /app/models/nakhlah_model.pth "$MODEL_URL" && \
        echo "Model downloaded: $(du -sh /app/models/nakhlah_model.pth)"; \
    else \
        echo "WARNING: MODEL_URL build arg not set. Model not bundled." && \
        echo "Set MODEL_URL on Render Build & Deploy settings."; \
    fi

ENV PYTHONUNBUFFERED=1
ENV MODEL_PATH=/app/models/nakhlah_model.pth

EXPOSE 10000

HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=3 \
    CMD curl -f http://localhost:10000/health || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "10000"]