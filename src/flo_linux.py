"""
flo - simple budget app — Linux launcher
Pure stdlib. Serves app.html, handles save/load.
"""
import os, sys, time, threading, json, subprocess, socket
import http.server, socketserver

# ── Locate bundled files ──────────────────────────────────────────────────────
if getattr(sys, "frozen", False):
    _BASE = sys._MEIPASS
else:
    _BASE = os.path.dirname(os.path.abspath(__file__))

_HTML_PATH = os.path.join(_BASE, "app.html")
try:
    with open(_HTML_PATH, "rb") as f:
        _APP_HTML = f.read()
except Exception as e:
    _APP_HTML = f"<html><body><h2>flo error</h2><p>{e}</p></body></html>".encode()

# ── Data storage ──────────────────────────────────────────────────────────────
_DATA_DIR  = os.path.join(
    os.environ.get("XDG_DATA_HOME", os.path.expanduser("~/.local/share")), "flo"
)
os.makedirs(_DATA_DIR, exist_ok=True)
_DATA_PATH = os.path.join(_DATA_DIR, "data.json")

WIN_W, WIN_H = 1100, 760
PORT_PREF    = 5757

# ── HTTP Handler ──────────────────────────────────────────────────────────────
class FloHandler(http.server.BaseHTTPRequestHandler):
    def log_message(self, fmt, *args): pass

    def do_OPTIONS(self):
        self.send_response(200)
        self._cors()
        self.end_headers()

    def do_GET(self):
        path = self.path.split("?")[0]
        if path in ("/", "/app.html"):
            self.send_response(200)
            self._cors()
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(_APP_HTML)))
            self.end_headers()
            self.wfile.write(_APP_HTML)
        elif path == "/api/load":
            data = {}
            if os.path.exists(_DATA_PATH):
                try:
                    with open(_DATA_PATH, "r", encoding="utf-8") as f:
                        data = json.load(f)
                except Exception:
                    pass
            self._json(data)
        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length)
        if self.path == "/api/save":
            try:
                data = json.loads(body)
                with open(_DATA_PATH, "w", encoding="utf-8") as f:
                    json.dump(data, f, indent=2, ensure_ascii=False)
                self._json({"ok": True})
            except Exception as e:
                self._json({"ok": False, "error": str(e)}, 500)
        else:
            self.send_response(404)
            self.end_headers()

    def _json(self, data, status=200):
        body = json.dumps(data).encode("utf-8")
        self.send_response(status)
        self._cors()
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")


# ── Threaded server so multiple requests don't block each other ───────────────
class ThreadedServer(socketserver.ThreadingMixIn, http.server.HTTPServer):
    daemon_threads = True


# ── Start server ──────────────────────────────────────────────────────────────
def start_server():
    for port in [PORT_PREF] + list(range(5758, 5800)):
        try:
            srv = ThreadedServer(("127.0.0.1", port), FloHandler)
            return srv, port
        except OSError:
            continue
    raise RuntimeError("No free port available")


def wait_for_server(port, timeout=15.0):
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            s = socket.create_connection(("127.0.0.1", port), timeout=0.3)
            s.close()
            return True
        except OSError:
            time.sleep(0.1)
    return False


# ── Find browser ──────────────────────────────────────────────────────────────
def find_browser():
    # Ensure snap and standard paths are in PATH
    for p in ["/snap/bin", "/usr/bin", "/usr/local/bin", "/bin"]:
        if p not in os.environ.get("PATH", ""):
            os.environ["PATH"] = p + ":" + os.environ.get("PATH", "")

    # Check explicit paths first
    for path in [
        "/usr/bin/chromium-browser",
        "/usr/bin/chromium",
        "/snap/bin/chromium",
        "/usr/bin/google-chrome",
        "/usr/bin/google-chrome-stable",
        "/usr/bin/brave-browser",
        "/opt/google/chrome/google-chrome",
    ]:
        if os.path.isfile(path) and os.access(path, os.X_OK):
            return path

    # PATH search fallback
    import shutil
    for name in ["chromium-browser", "chromium", "google-chrome",
                 "google-chrome-stable", "brave-browser"]:
        found = shutil.which(name)
        if found:
            return found

    return None


# ── Launch browser ────────────────────────────────────────────────────────────
def launch_browser(url, browser):
    profile = os.path.join(_DATA_DIR, "browser-profile")
    os.makedirs(profile, exist_ok=True)
    return subprocess.Popen(
        [browser,
         f"--app={url}",
         f"--window-size={WIN_W},{WIN_H}",
         f"--user-data-dir={profile}",
         "--no-first-run",
         "--no-default-browser-check",
         "--disable-extensions"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True,
    )


# ── Main ──────────────────────────────────────────────────────────────────────
def main():
    srv, port = start_server()
    url = f"http://127.0.0.1:{port}/app.html"

    # Start server in background thread
    t = threading.Thread(target=srv.serve_forever, daemon=True)
    t.start()

    # Wait for server to be ready
    if not wait_for_server(port):
        print("ERROR: server failed to start")
        return

    # Find and launch browser
    browser = find_browser()
    if not browser:
        print("ERROR: No Chromium browser found.")
        print("Install with: sudo apt install chromium-browser")
        try:
            subprocess.Popen(["zenity", "--error", "--no-wrap",
                              "--text=flo needs Chromium.\n\nInstall: sudo apt install chromium-browser"])
        except Exception:
            pass
        srv.shutdown()
        return

    proc = launch_browser(url, browser)
    proc.wait()

    # Clean up
    try:
        import signal
        os.killpg(os.getpgid(proc.pid), signal.SIGTERM)
    except Exception:
        pass

    srv.shutdown()


if __name__ == "__main__":
    main()
