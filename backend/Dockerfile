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

# ── Download model weights at build time ─────────────────────────────────────
# IMPORTANT: Always use /resolve/ URL (not /blob/) to get the raw file.
# /blob/ returns an HTML page → corrupted model file.
#
# Default URL points to HuggingFace raw file. Override with --build-arg:
#   docker build --build-arg MODEL_URL=https://... .
ARG MODEL_URL=https://huggingface.co/benfatah/NAKHLAH/resolve/main/nakhlah_robust_v1_best.pth

RUN mkdir -p /app/models && \
    echo "Downloading model from: $MODEL_URL" && \
    wget -q --show-progress \
         --header="User-Agent: Mozilla/5.0" \
         -O /app/models/nakhlah_robust_v1_best.pth \
         "$MODEL_URL" && \
    # Verify file is not HTML (corrupted download guard)
    if file /app/models/nakhlah_robust_v1_best.pth | grep -q "HTML"; then \
        echo "ERROR: Downloaded file is HTML — wrong URL used!" && exit 1; \
    fi && \
    echo "Model downloaded successfully: $(du -sh /app/models/nakhlah_robust_v1_best.pth)"

ENV PYTHONUNBUFFERED=1
# ✅ Correct path matching the actual filename
ENV MODEL_PATH=/app/models/nakhlah_robust_v1_best.pth

EXPOSE 10000

HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=3 \
    CMD curl -f http://localhost:10000/health || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "10000"]