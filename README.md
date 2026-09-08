# gestao3d-backup

Serviço separado para fazer backup diário do PostgreSQL do Gestão 3D e
armazenar os arquivos em um Railway Storage Bucket.

## Como funciona

1. `pg_dump` cria um dump PostgreSQL em formato custom.
2. O arquivo recebe um checksum SHA-256.
3. O `.dump` e o `.sha256` são enviados para o Railway Bucket.
4. Objetos antigos são removidos conforme `RETENTION_DAYS`.
5. O processo termina. Isso é importante para o Railway Cron.

## Variáveis

Obrigatórias:

- `DATABASE_URL`
- `BUCKET`
- `ACCESS_KEY_ID`
- `SECRET_ACCESS_KEY`
- `ENDPOINT`
- `REGION`

O Railway Bucket fornece essas credenciais na aba Credentials e também
permite usar Variable References.

O serviço não precisa de domínio público.

## Configuração sugerida

- `BACKUP_PREFIX=postgres`
- `RETENTION_DAYS=14`

## Cron sugerido

Para executar diariamente às 03:00 no horário de Brasília (UTC-3):

`0 6 * * *`

O Railway usa UTC para Cron Jobs.

## Teste manual

Antes de ativar o cron, faça um deploy e confira os logs. O serviço deve:

- conectar ao PostgreSQL;
- criar o dump;
- enviar o dump;
- enviar o checksum;
- remover somente arquivos mais antigos que a retenção;
- terminar com exit code 0.

## Restauração

Um dump no formato custom pode ser restaurado com `pg_restore`.

Exemplo conceitual:

`pg_restore --dbname="$DATABASE_URL" --clean --if-exists --no-owner --no-privileges backup.dump`

ATENÇÃO: restauração com `--clean` pode apagar objetos existentes no banco de destino.
Faça primeiro em um banco de teste.

## Segurança

- Nunca coloque `DATABASE_URL` ou as credenciais do Bucket no repositório.
- Não crie domínio público para este serviço.
- Não envie as credenciais para o chat.
