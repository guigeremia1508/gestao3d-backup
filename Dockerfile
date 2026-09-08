FROM postgres:17-bookworm

RUN apt-get update \
    && apt-get install -y --no-install-recommends awscli python3 ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY backup.sh cleanup.py ./
RUN chmod +x /app/backup.sh

CMD ["/app/backup.sh"]
