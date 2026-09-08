#!/usr/bin/env bash
set -Eeuo pipefail

: "${DATABASE_URL:?DATABASE_URL não configurada}"

if [[ "$DATABASE_URL" == postgresql://* || "$DATABASE_URL" == postgres://* ]]; then
    echo "DATABASE_URL OK - URL PostgreSQL detectada"
else
    echo "ERRO: DATABASE_URL não está em formato PostgreSQL"
fi

: "${BUCKET:?BUCKET não configurado}"
: "${ENDPOINT:?ENDPOINT não configurado}"

# Aceita tanto os nomes usados pelo Railway quanto os nomes simplificados
AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-${ACCESS_KEY_ID:-}}"
AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-${SECRET_ACCESS_KEY:-}}"
AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-${REGION:-auto}}"

export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION

: "${AWS_ACCESS_KEY_ID:?AWS_ACCESS_KEY_ID não configurada}"
: "${AWS_SECRET_ACCESS_KEY:?AWS_SECRET_ACCESS_KEY não configurada}"

BACKUP_PREFIX="${BACKUP_PREFIX:-postgres}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"

TIMESTAMP="$(date -u '+%Y%m%d-%H%M%S')"
FILENAME="gestao3d-${TIMESTAMP}.dump"
CHECKSUM="${FILENAME}.sha256"

TMP_DIR="$(mktemp -d)"
FILE="${TMP_DIR}/${FILENAME}"

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

echo "======================================"
echo "Gestão 3D - Backup PostgreSQL"
echo "======================================"
echo "Data UTC: ${TIMESTAMP}"
echo

echo "1. Criando dump do PostgreSQL..."

pg_dump \
    --dbname="$DATABASE_URL" \
    --format=custom \
    --no-owner \
    --no-privileges \
    --file="$FILE"

echo "Dump criado."

echo "2. Calculando SHA-256..."

(
    cd "$TMP_DIR"
    sha256sum "$FILENAME" > "$CHECKSUM"
)

echo "Checksum criado."

echo "3. Enviando backup para o Railway Bucket..."

aws s3 cp \
    "$FILE" \
    "s3://${BUCKET}/${BACKUP_PREFIX}/${FILENAME}" \
    --endpoint-url "$ENDPOINT"

aws s3 cp \
    "${TMP_DIR}/${CHECKSUM}" \
    "s3://${BUCKET}/${BACKUP_PREFIX}/${CHECKSUM}" \
    --endpoint-url "$ENDPOINT"

echo "Backup enviado."

echo "4. Limpando backups antigos..."

CUTOFF="$(date -u -d "${RETENTION_DAYS} days ago" '+%Y-%m-%dT%H:%M:%SZ')"

aws s3api list-objects-v2 \
    --bucket "$BUCKET" \
    --prefix "${BACKUP_PREFIX}/" \
    --endpoint-url "$ENDPOINT" \
    --output json |
python3 /app/cleanup.py "$BUCKET" "$ENDPOINT" "$CUTOFF"

echo
echo "======================================"
echo "BACKUP CONCLUÍDO COM SUCESSO"
echo "======================================"