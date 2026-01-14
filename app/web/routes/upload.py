from __future__ import annotations

from pathlib import Path
from typing import List

from fastapi import APIRouter, File, Request, UploadFile
from fastapi.responses import JSONResponse

from app.infra.storage import save_bytes

# from uuid import uuid4
router = APIRouter()

UPLOAD_DIR = Path("data/uploads")
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)


@router.post("/upload")
async def upload(request: Request, files: List[UploadFile] = File(...)):
    saved = []

    base = str(request.base_url).rstrip("/")  # e.g. http://127.0.0.1:8000

    for f in files:
        # Basic safe filename handling: store with UUID + original suffix
        # suffix = Path(f.filename).suffix if f.filename else ""
        # v1: dest = UPLOAD_DIR / f"{uuid4().hex}{suffix}"

        content = await f.read()
        # v1: dest.write_bytes(content)
        rec = save_bytes(f.filename or "upload", content, f.content_type)

        saved.append(
            {
                "id": rec.id,
                # v1: "original_name": f.filename,
                "original_name": rec.original_name,
                "bytes": rec.bytes,
                # v1: "stored_name": dest.name,
                # v1: "bytes": len(content),
                # v1: "content_type": f.content_type,
                "content_type": rec.content_type,
                "view_url": f"{base}/p/{rec.id}",
                "download_url": f"{base}/f/{rec.id}",
            }
        )
    return JSONResponse({"ok": True, "saved": saved})
