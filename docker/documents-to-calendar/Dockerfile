# Use Python slim image for ARM64
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc g++ \
    build-essential \
    libffi-dev \
    libjpeg-dev \
    zlib1g-dev \
    libpng-dev \
    python3-pymupdf \
    python3-pymupdf-tools \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY backend/requirements.txt .
# Remove pymupdf if still in requirements
RUN sed -i '/pymupdf/d' requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application code
COPY backend/ /app/backend/
COPY frontend/ /app/frontend/

# Expose port
EXPOSE 8000

# Set environment variables (can also come from .env)
ENV PYTHONUNBUFFERED=1

# Start the FastAPI app with uvicorn
CMD ["uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "8000"]
