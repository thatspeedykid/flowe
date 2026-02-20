"""
flo - simple budget app
Linux launcher. Serves app.html from memory — no file path issues.
Pure stdlib only.
"""
import os, sys, time, socket, threading, json, subprocess, webbrowser
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
    _APP_HTML = f"""<!DOCTYPE html><html><body style="font:16px sans-serif;padding:40px">
    <h2>flo could not start</h2>
    <p>Could not load app.html from: <code>{_HTML_PATH}</code></p>
    <p>Error: {_e}</p>
    </body></html>""".encode()

_DATA_DIR  = os.path.join(
    os.environ.get("XDG_DATA_HOME", os.path.expanduser("~/.local/share")), "flo"
)
os.makedirs(_DATA_DIR, exist_ok=True)
_DATA_PATH = os.path.join(_DATA_DIR, "data.json")

WIN_W, WIN_H = 1100, 760
PORT_PREF    = 5757


class FloHandler(http.server.BaseHTTPRequestHandler):
    def log_message(self, fmt, *args): pass

    def do_OPTIONS(self):
        self.send_response(200); self._cors(); self.end_headers()

    def do_GET(self):
        p = self.path.split("?")[0]
        if p in ("/", "/app.html"):
            self.send_response(200); self._cors()
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", len(_APP_HTML))
            self.end_headers(); self.wfile.write(_APP_HTML)
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
    for port in [PORT_PREF] + list(range(5758, 5800)):
        try:
            srv = http.server.HTTPServer(("127.0.0.1", port), FloHandler)
            threading.Thread(target=srv.serve_forever, daemon=True).start()
            return port
        except OSError: continue
    raise RuntimeError("No free port")


def wait_for_server(port, timeout=10.0):
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            with socket.create_connection(("127.0.0.1", port), timeout=0.2): return True
        except OSError: time.sleep(0.05)
    return False


def find_browser():
    import shutil
    for name in ["google-chrome", "google-chrome-stable", "chromium",
                 "chromium-browser", "brave-browser", "microsoft-edge"]:
        path = shutil.which(name)
        if path: return path
    return None


def launch_browser(url, browser_path):
    profile = os.path.join(_DATA_DIR, "browser-profile")
    os.makedirs(profile, exist_ok=True)
    return subprocess.Popen(
        [browser_path, f"--app={url}", f"--window-size={WIN_W},{WIN_H}",
         f"--user-data-dir={profile}", "--no-first-run",
         "--no-default-browser-check", "--disable-extensions",
         "--disable-background-networking", "--disable-sync"],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )


def main():
    port = start_server()
    wait_for_server(port)
    url = f"http://127.0.0.1:{port}/app.html"
    browser = find_browser()
    if browser:
        proc = launch_browser(url, browser)
        proc.wait()
    else:
        webbrowser.open(url)
        try:
            while True: time.sleep(1)
        except KeyboardInterrupt: pass


if __name__ == "__main__":
    main()
