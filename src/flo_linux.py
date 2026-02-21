"""
flo - simple budget app
Linux launcher. Serves app.html from memory. Pure stdlib.
"""
import os, sys, time, threading, json, subprocess, webbrowser
import http.server

if getattr(sys, "frozen", False):
    _BASE = sys._MEIPASS
else:
    _BASE = os.path.dirname(os.path.abspath(__file__))

_HTML_PATH = os.path.join(_BASE, "app.html")
try:
    with open(_HTML_PATH, "rb") as _f:
        _APP_HTML = _f.read()
except Exception as _e:
    _APP_HTML = f"<html><body><h2>flo could not start</h2><p>{_e}</p></body></html>".encode()

_DATA_DIR  = os.path.join(
    os.environ.get("XDG_DATA_HOME", os.path.expanduser("~/.local/share")), "flo"
)
os.makedirs(_DATA_DIR, exist_ok=True)
_DATA_PATH = os.path.join(_DATA_DIR, "data.json")

WIN_W, WIN_H = 1100, 760
PORT_PREF    = 5757


def get_html(port):
    """Inject the actual bound port so JS always hits the right address."""
    return _APP_HTML.replace(
        b"const API='http://127.0.0.1:5757'",
        f"const API='http://127.0.0.1:{port}'".encode()
    )


class FloHandler(http.server.BaseHTTPRequestHandler):
    def log_message(self, fmt, *args): pass

    def do_OPTIONS(self):
        self.send_response(200); self._cors(); self.end_headers()

    def do_GET(self):
        p = self.path.split("?")[0]
        if p in ("/", "/app.html"):
            html = get_html(self.server.server_address[1])
            self.send_response(200); self._cors()
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", len(html))
            self.end_headers(); self.wfile.write(html)
        elif p == "/api/load":
            data = {}
            if os.path.exists(_DATA_PATH):
                try:
                    with open(_DATA_PATH, "r", encoding="utf-8") as f:
                        data = json.load(f)
                except Exception: pass
            self._json(data)
        else:
            self.send_response(404); self.end_headers()

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        body   = self.rfile.read(length)
        if self.path == "/api/save":
            try:
                data = json.loads(body)
                with open(_DATA_PATH, "w", encoding="utf-8") as f:
                    json.dump(data, f, indent=2, ensure_ascii=False)
                self._json({"ok": True})
            except Exception as e:
                self._json({"ok": False, "error": str(e)}, 500)
        else:
            self.send_response(404); self.end_headers()

    def _json(self, data, status=200):
        body = json.dumps(data).encode("utf-8")
        self.send_response(status); self._cors()
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", len(body))
        self.end_headers(); self.wfile.write(body)

    def _cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")


def start_server():
    """Bind synchronously. Returns (server, port, is_new)."""
    for port in [PORT_PREF] + list(range(5758, 5800)):
        try:
            srv = http.server.HTTPServer(("127.0.0.1", port), FloHandler)
            return srv, port, True
        except OSError:
            if port == PORT_PREF:
                return None, port, False
            continue
    raise RuntimeError("No free port")


def wait_for_http(port, timeout=20.0):
    """Poll until real HTTP 200 — guarantees serve_forever is running."""
    import socket
    req = b"GET /app.html HTTP/1.0\r\nHost: 127.0.0.1\r\n\r\n"
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            s = socket.socket()
            s.settimeout(0.5)
            s.connect(("127.0.0.1", port))
            s.sendall(req)
            resp = s.recv(64).decode("utf-8", errors="ignore")
            s.close()
            if "200" in resp:
                return True
        except Exception:
            pass
        time.sleep(0.05)
    return False


def find_browser():
    """Returns (path, kind) — Chromium-based only for proper --app= mode."""
    import shutil

    # Expand PATH to include snap and other common locations
    extra_paths = [
        "/snap/bin", "/usr/bin", "/usr/local/bin",
        "/bin", "/opt/google/chrome",
    ]
    env_path = os.environ.get("PATH", "")
    for p in extra_paths:
        if p not in env_path:
            env_path = p + ":" + env_path
    os.environ["PATH"] = env_path

    # Check explicit known paths (covers snap, deb, flatpak installs)
    explicit_paths = [
        "/usr/bin/chromium-browser",
        "/usr/bin/chromium",
        "/snap/bin/chromium",
        "/usr/bin/google-chrome",
        "/usr/bin/google-chrome-stable",
        "/usr/bin/brave-browser",
        "/usr/bin/microsoft-edge",
        "/opt/google/chrome/google-chrome",
    ]
    for path in explicit_paths:
        if os.path.isfile(path) and os.access(path, os.X_OK):
            return path, "chromium"

    # Also search updated PATH
    for name in ["chromium-browser", "chromium", "google-chrome",
                 "google-chrome-stable", "brave-browser", "microsoft-edge"]:
        path = shutil.which(name)
        if path: return path, "chromium"

    return None, None


def launch_browser(url, browser_path, kind="chromium"):
    profile = os.path.join(_DATA_DIR, "browser-profile")
    os.makedirs(profile, exist_ok=True)
    cmd = [browser_path, f"--app={url}", f"--window-size={WIN_W},{WIN_H}",
           f"--user-data-dir={profile}", "--no-first-run",
           "--no-default-browser-check", "--disable-extensions",
           "--disable-background-networking", "--disable-sync"]
    return subprocess.Popen(
        cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        start_new_session=True
    )


def main():
    srv, port, is_new = start_server()

    if not is_new:
        url = f"http://127.0.0.1:{port}/app.html"
        browser, kind = find_browser()
        if browser:
            launch_browser(url, browser).wait()
        else:
            print("No Chromium browser found. Install Chromium: sudo apt install chromium-browser")
        return

    url = f"http://127.0.0.1:{port}/app.html"

    def open_browser():
        wait_for_http(port)
        browser, kind = find_browser()
        if browser:
            proc = launch_browser(url, browser)
            proc.wait()
            try:
                import signal
                os.killpg(os.getpgid(proc.pid), signal.SIGTERM)
            except Exception:
                pass
        else:
            # Show visible error dialog using zenity or xmessage
            msg = "flo needs Chromium to run.\nInstall it with:\n\n  sudo apt install chromium-browser"
            try:
                subprocess.Popen(["zenity", "--error", "--text", msg])
            except Exception:
                try:
                    subprocess.Popen(["xmessage", msg])
                except Exception:
                    print(msg)
            srv.shutdown()
            os._exit(1)
        srv.shutdown()
        os._exit(0)

    threading.Thread(target=open_browser, daemon=True).start()

    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
