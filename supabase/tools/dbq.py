"""Read-only questions to the linked Supabase database, through the CLI.

Uses `supabase db query --linked` (you are already logged in and linked for
`supabase db push`). Only SELECTs are sent by the tools in this folder.
"""

from __future__ import annotations

import json
import os
import subprocess
import tempfile


def rows(sql: str) -> list[dict]:
    with tempfile.NamedTemporaryFile("w", suffix=".sql", delete=False,
                                     encoding="utf-8") as f:
        f.write(sql)
        path = f.name
    try:
        out = subprocess.run(
            ["supabase", "db", "query", "--linked", "-f", path],
            capture_output=True, text=True, encoding="utf-8",
            shell=(os.name == "nt"),
        )
    finally:
        os.unlink(path)
    text = out.stdout
    start = text.find("{")
    if out.returncode != 0 or start < 0:
        raise SystemExit("the database did not answer:\n" + (out.stderr or text)[-600:])
    return json.loads(text[start:]).get("rows", [])
