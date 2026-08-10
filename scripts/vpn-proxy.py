#!/usr/bin/env python3
"""TCP proxy on Mac host so Docker auth-service can reach VPN-internal Orange APIs."""
from __future__ import annotations

import argparse
import socket
import socketserver
import sys
import threading


class ForwardHandler(socketserver.BaseRequestHandler):
    remote_host: str = ""
    remote_port: int = 0

    def handle(self) -> None:
        remote = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        remote.settimeout(30)
        try:
            remote.connect((self.remote_host, self.remote_port))
        except OSError as exc:
            print(f"[vpn-proxy] connect failed {self.remote_host}:{self.remote_port} — {exc}", flush=True)
            return

        client = self.request
        client.settimeout(30)

        def pipe(src: socket.socket, dst: socket.socket) -> None:
            try:
                while True:
                    data = src.recv(65536)
                    if not data:
                        break
                    dst.sendall(data)
            except OSError:
                pass
            finally:
                try:
                    dst.shutdown(socket.SHUT_WR)
                except OSError:
                    pass

        t1 = threading.Thread(target=pipe, args=(client, remote), daemon=True)
        t2 = threading.Thread(target=pipe, args=(remote, client), daemon=True)
        t1.start()
        t2.start()
        t1.join()
        t2.join()
        remote.close()


def make_server(local_port: int, remote_host: str, remote_port: int) -> socketserver.ThreadingTCPServer:
    handler = type(
        f"Handler{local_port}",
        (ForwardHandler,),
        {"remote_host": remote_host, "remote_port": remote_port},
    )
    server = socketserver.ThreadingTCPServer(("0.0.0.0", local_port), handler)
    server.daemon_threads = True
    server.allow_reuse_address = True
    return server


def main() -> int:
    parser = argparse.ArgumentParser(description="VPN TCP proxy for Docker → Orange APIs")
    parser.add_argument("--sso-target", default="10.4.3.27:9001")
    parser.add_argument("--email-target", default="preprod-notification.xyz.jt.jtgroup:80")
    parser.add_argument("--sso-port", type=int, default=19001)
    parser.add_argument("--email-port", type=int, default=19002)
    args = parser.parse_args()

    def split_target(value: str) -> tuple[str, int]:
        host, _, port = value.partition(":")
        return host, int(port or "80")

    sso_host, sso_port = split_target(args.sso_target)
    email_host, email_port = split_target(args.email_target)

    servers: list[socketserver.ThreadingTCPServer] = []
    for local_port, remote_host, remote_port in (
        (args.sso_port, sso_host, sso_port),
        (args.email_port, email_host, email_port),
    ):
        try:
            server = make_server(local_port, remote_host, remote_port)
            servers.append(server)
            threading.Thread(target=server.serve_forever, daemon=True).start()
            print(
                f"[vpn-proxy] :{local_port} → {remote_host}:{remote_port}",
                flush=True,
            )
        except OSError as exc:
            print(f"[vpn-proxy] failed to bind :{local_port} — {exc}", flush=True)
            return 1

    print("[vpn-proxy] running — stop with Ctrl+C", flush=True)
    try:
        while True:
            threading.Event().wait(timeout=3600)
    except KeyboardInterrupt:
        print("[vpn-proxy] stopped", flush=True)
    for server in servers:
        server.shutdown()
    return 0


if __name__ == "__main__":
    sys.exit(main())
