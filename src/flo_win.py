"""
flo - simple budget app
Windows launcher. Serves app.html from memory — no file path issues.
Pure stdlib. No pywebview. No pythonnet. No .NET SDK.
"""
import os, sys, time, socket, threading, json, subprocess, webbrowser
import http.server

# ── Locate app.html at startup ───────────────────────────────────────────────
# PyInstaller extracts datas to sys._MEIPASS.
# Running as .py: files are next to this script.
if getattr(sys, "frozen", False):
    _BASE = sys._MEIPASS
else:
    _BASE = os.path.dirname(os.path.abspath(__file__))

_HTML_PATH = os.path.join(_BASE, "app.html")

# Read the whole HTML into memory RIGHT NOW, before any threading starts.
# This is the key fix: we never touch the filesystem path again after this.
try:
    with open(_HTML_PATH, "rb") as _f:
        _APP_HTML = _f.read()
except Exception as _e:
    # If we can't find app.html, show a useful error page instead of crashing
    _APP_HTML = f"""<!DOCTYPE html><html><body style="font:16px sans-serif;padding:40px">
    <h2>flo could not start</h2>
    <p>Could not load app.html from: <code>{_HTML_PATH}</code></p>
    <p>Error: {_e}</p>
    </body></html>""".encode()

# ── Data dir (APPDATA\flo) ────────────────────────────────────────────────────
_DATA_DIR  = os.path.join(os.environ.get("APPDATA", os.path.expanduser("~")), "flo")
os.makedirs(_DATA_DIR, exist_ok=True)
_DATA_PATH = os.path.join(_DATA_DIR, "data.json")

CREATE_NO_WINDOW = 0x08000000
WIN_W, WIN_H     = 1100, 760
PORT_PREF        = 5757


# ── HTTP handler — serves from memory, not filesystem ────────────────────────
class FloHandler(http.server.BaseHTTPRequestHandler):

    def log_message(self, fmt, *args):
        pass  # silent

    def do_OPTIONS(self):
        self.send_response(200)
        self._cors()
        self.end_headers()

    def do_GET(self):
        p = self.path.split("?")[0]  # strip query strings

        if p in ("/", "/app.html"):
            # Serve the in-memory HTML — no file I/O, no path issues
            self.send_response(200)
            self._cors()
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", len(_APP_HTML))
            self.end_headers()
            self.wfile.write(_APP_HTML)

        elif p == "/api/load":
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
            self.send_response(404)
            self.end_headers()

    def _json(self, data, status=200):
        body = json.dumps(data).encode("utf-8")
        self.send_response(status)
        self._cors()
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", len(body))
        self.end_headers()
        self.wfile.write(body)

    def _cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")


# ── Server startup ────────────────────────────────────────────────────────────
def start_server():
    for port in [PORT_PREF] + list(range(5758, 5800)):
        try:
            srv = http.server.HTTPServer(("127.0.0.1", port), FloHandler)
            threading.Thread(target=srv.serve_forever, daemon=True).start()
            return port
        except OSError:
            continue
    raise RuntimeError("Could not bind to any port")


def wait_for_server(port, timeout=10.0):
    """Block until the server is actually accepting connections."""
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            with socket.create_connection(("127.0.0.1", port), timeout=0.2):
                return True
        except OSError:
            time.sleep(0.05)
    return False


# ── Browser launcher ──────────────────────────────────────────────────────────
def find_browser():
    lad  = os.environ.get("LOCALAPPDATA", "")
    pf   = os.environ.get("PROGRAMFILES",       r"C:\Program Files")
    pf86 = os.environ.get("PROGRAMFILES(X86)",  r"C:\Program Files (x86)")
    for path in [
        os.path.join(pf86, r"Microsoft\Edge\Application\msedge.exe"),
        os.path.join(pf,   r"Microsoft\Edge\Application\msedge.exe"),
        os.path.join(lad,  r"Microsoft\Edge\Application\msedge.exe"),
        os.path.join(pf,   r"Google\Chrome\Application\chrome.exe"),
        os.path.join(pf86, r"Google\Chrome\Application\chrome.exe"),
        os.path.join(lad,  r"Google\Chrome\Application\chrome.exe"),
        os.path.join(pf,   r"BraveSoftware\Brave-Browser\Application\brave.exe"),
        os.path.join(lad,  r"BraveSoftware\Brave-Browser\Application\brave.exe"),
    ]:
        if path and os.path.exists(path):
            return path
    return None


def launch_browser(url, browser_path):
    profile = os.path.join(_DATA_DIR, "browser-profile")
    os.makedirs(profile, exist_ok=True)
    return subprocess.Popen(
        [
            browser_path,
            f"--app={url}",
            f"--window-size={WIN_W},{WIN_H}",
            f"--user-data-dir={profile}",
            "--no-first-run",
            "--no-default-browser-check",
            "--disable-extensions",
            "--disable-background-networking",
            "--disable-sync",
            "--disable-translate",
            "--hide-crash-restore-bubble",
        ],
        creationflags=CREATE_NO_WINDOW,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


# ── Main ──────────────────────────────────────────────────────────────────────
def main():
    port = start_server()

    if not wait_for_server(port):
        # Server didn't start — open error in browser as fallback
        webbrowser.open(f"http://127.0.0.1:{port}/app.html")
        time.sleep(10)
        return

    url     = f"http://127.0.0.1:{port}/app.html"
    browser = find_browser()

    if browser:
        proc = launch_browser(url, browser)
        proc.wait()   # keep Python (and the server) alive until window closes
    else:
        # No Chromium-based browser found — open in default browser
        webbrowser.open(url)
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            pass


if __name__ == "__main__":
    main()
