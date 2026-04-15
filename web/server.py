"""WebSocket bridge between browser and OpenHarness backend."""

from __future__ import annotations

import argparse
import asyncio
import json
import logging
import os
import signal
import sys
from pathlib import Path

from starlette.applications import Starlette
from starlette.responses import FileResponse
from starlette.routing import Route, WebSocketRoute
from starlette.websockets import WebSocket, WebSocketDisconnect

import uvicorn

log = logging.getLogger("web-chat")

PROTOCOL_PREFIX = "OHJSON:"

# Track active subprocesses for cleanup
_active_processes: set[asyncio.subprocess.Process] = set()


def _build_oh_command(cfg: argparse.Namespace) -> list[str]:
    cmd = [
        sys.executable, "-m", "openharness",
        "--backend-only",
        "--cwd", cfg.cwd,
    ]
    if cfg.permission_mode:
        cmd += ["--permission-mode", cfg.permission_mode]
    if cfg.model:
        cmd += ["--model", cfg.model]
    return cmd


async def _kill_process(proc: asyncio.subprocess.Process) -> None:
    """Gracefully terminate, then force-kill after timeout."""
    if proc.returncode is not None:
        return
    try:
        proc.terminate()
        try:
            await asyncio.wait_for(proc.wait(), timeout=3)
        except asyncio.TimeoutError:
            proc.kill()
            await proc.wait()
    except ProcessLookupError:
        pass
    finally:
        _active_processes.discard(proc)


async def ws_endpoint(websocket: WebSocket) -> None:
    await websocket.accept()

    cfg = websocket.app.state.cfg
    cmd = _build_oh_command(cfg)
    log.info("Spawning: %s", " ".join(cmd))

    proc = await asyncio.create_subprocess_exec(
        *cmd,
        stdin=asyncio.subprocess.PIPE,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
        env={**os.environ, "PYTHONUNBUFFERED": "1"},
    )
    _active_processes.add(proc)

    async def stdout_reader() -> None:
        """Read oh backend stdout and forward OHJSON events to WebSocket."""
        assert proc.stdout is not None
        while True:
            raw = await proc.stdout.readline()
            if not raw:
                break
            line = raw.decode("utf-8", errors="replace").rstrip("\n")
            if line.startswith(PROTOCOL_PREFIX):
                payload = line[len(PROTOCOL_PREFIX):]
                await websocket.send_text(payload)
            elif line.strip():
                await websocket.send_text(json.dumps({
                    "type": "transcript_item",
                    "item": {"role": "log", "text": line},
                }))

    async def stderr_reader() -> None:
        """Read oh backend stderr and forward as log entries."""
        assert proc.stderr is not None
        while True:
            raw = await proc.stderr.readline()
            if not raw:
                break
            line = raw.decode("utf-8", errors="replace").rstrip("\n")
            if line.strip():
                log.debug("oh stderr: %s", line)

    async def ws_reader() -> None:
        """Read WebSocket messages and write to oh backend stdin."""
        assert proc.stdin is not None
        while True:
            data = await websocket.receive_text()
            proc.stdin.write((data + "\n").encode("utf-8"))
            await proc.stdin.drain()

    stdout_task = asyncio.create_task(stdout_reader())
    stderr_task = asyncio.create_task(stderr_reader())
    ws_task = asyncio.create_task(ws_reader())

    try:
        done, pending = await asyncio.wait(
            [stdout_task, stderr_task, ws_task],
            return_when=asyncio.FIRST_COMPLETED,
        )
        for task in done:
            exc = task.exception() if not task.cancelled() else None
            if exc and not isinstance(exc, WebSocketDisconnect):
                log.error("Task error: %s", exc)
    except Exception as exc:
        log.error("Session error: %s", exc)
    finally:
        for task in [stdout_task, stderr_task, ws_task]:
            task.cancel()
            try:
                await task
            except (asyncio.CancelledError, Exception):
                pass
        await _kill_process(proc)
        try:
            await websocket.close()
        except Exception:
            pass
        log.info("Session cleaned up")


async def homepage(request) -> FileResponse:
    html_path = Path(__file__).parent / "index.html"
    return FileResponse(html_path, media_type="text/html")


def create_app(cfg: argparse.Namespace) -> Starlette:
    app = Starlette(
        routes=[
            Route("/", homepage),
            WebSocketRoute("/ws", ws_endpoint),
        ],
    )
    app.state.cfg = cfg
    return app


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Web Chat UI for OpenHarness")
    parser.add_argument("--port", type=int, default=8765)
    parser.add_argument("--host", default="0.0.0.0")
    parser.add_argument("--cwd", default=str(Path.cwd()))
    parser.add_argument("--permission-mode", default="default")
    parser.add_argument("--model", default=None)
    parser.add_argument("--debug", action="store_true")
    return parser.parse_args()


def main() -> None:
    cfg = parse_args()

    level = logging.DEBUG if cfg.debug else logging.INFO
    logging.basicConfig(
        level=level,
        format="%(asctime)s [%(name)s] %(levelname)s %(message)s",
        stream=sys.stderr,
    )

    # Cleanup on exit
    def _cleanup(signum, frame):
        for proc in list(_active_processes):
            try:
                proc.kill()
            except Exception:
                pass
        sys.exit(0)

    signal.signal(signal.SIGTERM, _cleanup)
    signal.signal(signal.SIGINT, _cleanup)

    app = create_app(cfg)
    log.info("Starting web-chat on http://%s:%d", cfg.host, cfg.port)
    log.info("OH working directory: %s", cfg.cwd)

    uvicorn.run(app, host=cfg.host, port=cfg.port, log_level="info")


if __name__ == "__main__":
    main()
