ARG ARCH=amd64

FROM ghcr.io/defenseunicorns/leapfrogai/python:3.11-dev-${ARCH} as builder

WORKDIR /leapfrogai

RUN python -m venv .venv
RUN source .venv/bin/activate

COPY requirements.txt .
RUN pip install -r requirements.txt --user

ENV EMBEDDING_MODEL_NAME=hkunlp/instructor-xl
COPY tools/cache_embeddings.py .
RUN python cache_embeddings.py

FROM ghcr.io/defenseunicorns/leapfrogai/python:3.11-${ARCH}

WORKDIR /leapfrogai

COPY --from=builder /home/nonroot/.local/lib/python3.11/site-packages /home/nonroot/.local/lib/python3.11/site-packages
COPY --from=builder /home/nonroot/.local/bin/uvicorn /home/nonroot/.local/bin/uvicorn
COPY --from=builder /leapfrogai/embedding-cache/ /leapfrogai/embedding-cache/
COPY --from=builder /leapfrogai/tokenizer-cache/ /leapfrogai/tokenizer-cache/

COPY src/ .

EXPOSE 8000

ENTRYPOINT ["/home/nonroot/.local/bin/uvicorn", "main:app", "--proxy-headers", "--host", "0.0.0.0", "--port", "8000"]