import sys
import json
import subprocess
from datetime import datetime, timezone


bucket = sys.argv[1]
endpoint = sys.argv[2]
cutoff_text = sys.argv[3]

# Converte a data recebida para datetime
cutoff_text = cutoff_text.replace("Z", "+00:00")
cutoff = datetime.fromisoformat(cutoff_text)

if cutoff.tzinfo is None:
    cutoff = cutoff.replace(tzinfo=timezone.utc)

# Lê a resposta do aws s3api list-objects-v2
data = json.load(sys.stdin)

contents = data.get("Contents", [])

deleted = 0

for obj in contents:
    key = obj.get("Key")
    last_modified = obj.get("LastModified")

    if not key or not last_modified:
        continue

    last_modified = last_modified.replace("Z", "+00:00")
    modified = datetime.fromisoformat(last_modified)

    if modified.tzinfo is None:
        modified = modified.replace(tzinfo=timezone.utc)

    if modified < cutoff:
        print(f"Removendo backup antigo: {key}")

        subprocess.run(
            [
                "aws",
                "s3api",
                "delete-object",
                "--bucket",
                bucket,
                "--key",
                key,
                "--endpoint-url",
                endpoint,
            ],
            check=True,
        )

        deleted += 1

print(f"Limpeza concluída. Arquivos removidos: {deleted}")