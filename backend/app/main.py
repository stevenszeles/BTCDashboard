import logging
import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from .config import settings
from .routers import portfolio, risk, trades, status
from .routers import auth, broker, market, positions, admin
from .workers import start_workers
from .db import ensure_schema

_log_path = settings.log_path
try:
    log_dir = os.path.dirname(os.path.abspath(_log_path))
    if log_dir:
        os.makedirs(log_dir, exist_ok=True)
    logging.basicConfig(
        filename=_log_path,
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(message)s",
    )
except Exception:
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
    logging.getLogger(__name__).warning("Failed to initialize file logging at %s.", _log_path)

app = FastAPI(title="Workstation", docs_url=None, redoc_url=None)

allow_all = os.getenv("WS_ALLOW_ALL_ORIGINS", "0") == "1"
if not allow_all and settings.static_mode and not os.getenv("ALLOWED_ORIGINS"):
    allow_all = True
if allow_all:
    allowed_origins = ["*"]
else:
    allowed_origins = [
        origin.strip()
        for origin in os.getenv(
            "ALLOWED_ORIGINS",
            "https://localhost:8000,https://127.0.0.1:8000,http://localhost:8000,http://127.0.0.1:8000,http://localhost:5173",
        ).split(",")
        if origin.strip()
    ]

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=False if allow_all else True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["Content-Type", "Authorization"],
    max_age=600,
)

app.include_router(portfolio.router, prefix=settings.api_prefix)
app.include_router(risk.router, prefix=settings.api_prefix)
app.include_router(trades.router, prefix=settings.api_prefix)
app.include_router(status.router, prefix=settings.api_prefix)
app.include_router(auth.router, prefix=settings.api_prefix)
app.include_router(broker.router, prefix=settings.api_prefix)
app.include_router(market.router, prefix=settings.api_prefix)
app.include_router(positions.router, prefix=settings.api_prefix)
app.include_router(admin.router, prefix=settings.api_prefix)

STATIC_DIR = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "..", "frontend", "dist")
)
if os.path.isdir(STATIC_DIR):
    app.mount("/", StaticFiles(directory=STATIC_DIR, html=True), name="static")
else:
    logging.getLogger(__name__).warning("Static assets not found at %s. Build the frontend before deployment.", STATIC_DIR)


@app.get("/health")
def health():
    return {"status": "ok"}


@app.on_event("startup")
def _startup():
    ensure_schema()
    start_workers()
