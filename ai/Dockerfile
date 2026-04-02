FROM python:3.10-slim

WORKDIR /app

# system deps (important for opencv / numpy sometimes)
RUN apt-get update && apt-get install -y \
    gcc \
    libgl1 \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8001

CMD ["uvicorn", "src.inference_api:app", "--host", "0.0.0.0", "--port", "8001"]