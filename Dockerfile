FROM python:3.14-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

RUN useradd --create-home --uid 10001 appuser

COPY app/ ./app/

USER appuser

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

FROM base AS test

USER root

COPY requirements-dev.txt .
RUN pip install --no-cache-dir -r requirements-dev.txt

COPY tests/ ./tests/

USER appuser

CMD ["python", "-m", "pytest", "-q", "-p", "no:cacheprovider", "tests/"]


FROM base AS runtime

USER root

RUN python -m pip uninstall --yes pip \
    && python -c "import ensurepip, shutil; from pathlib import Path; shutil.rmtree(Path(ensurepip.__file__).parent)"

USER appuser