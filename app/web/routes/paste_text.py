from __future__ import annotations

from datetime import datetime

from fastapi import APIRouter, Form, Request
from fastapi.responses import JSONResponse

from app.infra.storage import save_bytes

router = APIRouter()

@router.post("/paste")
async def paste_text(
    request: Request,
    content: str = Form(...),
    language: str = Form("plaintext"),   # optional; used for highlighting
):
    # store as .txt
    name = f"paste-{datetime.utcnow().strftime('%Y%m%d%H%M%S')}.txt"
    rec = save_bytes(name, content.encode("utf-8"), "text/plain")

    base = str(request.base_url).rstrip("/")
    return JSONResponse({
        "ok": True,
        "id": rec.id,
        "view_url": f"{base}/p/{rec.id}?lang={language}",
        "download_url": f"{base}/f/{rec.id}",
    })

