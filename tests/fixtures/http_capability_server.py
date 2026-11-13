#!/usr/bin/env python3
"""Loopback-only HTTP fixture for the NOX client capability audit."""

from __future__ import annotations

import gzip
import socketserver
import ssl
import sys
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


class LoopbackHTTPServer(ThreadingHTTPServer):
    def server_bind(self) -> None:
        socketserver.TCPServer.server_bind(self)
        self.server_name = "127.0.0.1"
        self.server_port = self.server_address[1]


class CapabilityHandler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, format: str, *args: object) -> None:
        return

    def _read_body(self) -> bytes:
        length = int(self.headers.get("Content-Length", "0"))
        return self.rfile.read(length)

    def _send(self, status: int, body: bytes, headers: dict[str, str] | None = None) -> None:
        self.send_response(status)
        for name, value in (headers or {}).items():
            self.send_header(name, value)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        if self.command != "HEAD":
            try:
                self.wfile.write(body)
            except (BrokenPipeError, ConnectionResetError):
                pass

    def do_POST(self) -> None:
        if self.path != "/echo":
            self._send(404, b"not-found")
            return
        body = self._read_body()
        self._send(
            201,
            body,
            {
                "Content-Type": "application/octet-stream",
                "X-Seen-Method": self.command,
                "X-Seen-Probe": self.headers.get("X-Pulse-Probe", ""),
            },
        )

    def do_GET(self) -> None:
        if self.path == "/binary":
            self._send(200, bytes((65, 0, 255, 66)), {"Content-Type": "application/octet-stream"})
        elif self.path == "/redirect":
            self._send(302, b"redirect-not-followed", {"Location": "/final"})
        elif self.path == "/final":
            self._send(200, b"redirect-followed")
        elif self.path == "/status":
            self._send(503, b"temporarily-unavailable", {"Retry-After": "1"})
        elif self.path == "/gzip":
            self._send(200, gzip.compress(b"gzip-decoded"), {"Content-Encoding": "gzip"})
        elif self.path == "/slow":
            time.sleep(0.25)
            self._send(200, b"too-late")
        else:
            self._send(404, b"not-found")


def main() -> None:
    if len(sys.argv) not in (2, 4):
        raise SystemExit("usage: http_capability_server.py <port-file> [<certificate> <private-key>]")
    server = LoopbackHTTPServer(("127.0.0.1", 0), CapabilityHandler)
    if len(sys.argv) == 4:
        context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        context.load_cert_chain(sys.argv[2], sys.argv[3])
        server.socket = context.wrap_socket(server.socket, server_side=True)
    Path(sys.argv[1]).write_text(str(server.server_port), encoding="ascii")
    server.serve_forever(poll_interval=0.05)


if __name__ == "__main__":
    main()
