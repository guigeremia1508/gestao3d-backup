import json
import subprocess
import sys
from datetime import datetime, timezone

bucket, endpoint, cutoff = sys.argv[1], sys.argv[2], int(sys.argv[3])
items = json.load(sys.stdin)

for item in items or []:
    key = item["Key"]
    modified = item["LastModified"]
    dt = datetime.fromisoformat(modified.replace("Z", "+00:00"))
    if dt.timestamp() < cutoff:
        print(f"Removendo: {key}")
        subprocess.run(
            [
                "aws", "s3", "rm", f"s3://{bucket}/{key}",
                "--endpoint-url", endpoint,
            ],
            check=True,
        )
