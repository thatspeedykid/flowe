"""
flo - simple budget app  
Windows launcher. Serves app.html from memory. Pure stdlib.
"""
import os, sys, time, threading, json, subprocess, webbrowser
import http.server

if getattr(sys, 'frozen', False):
    _BASE = sys._MEIPASS
else:
    _BASE = os.path.dirname(os.path.abspath(__file__))

_HTML_PATH = os.path.join(_BASE, 'app.html')
try:
    with open(_HTML_PATH, 'rb') as _f:
        _APP_HTML = _f.read()
except Exception as _e:
    _APP_HTML = f'<html><body><h2>flo could not start</h2><p>{_e}</p></body></html>'.encode()

_DATA_DIR  = os.path.join(os.environ.get('APPDATA', os.path.expanduser('~')), 'flo')
os.makedirs(_DATA_DIR, exist_ok=True)
_DATA_PATH = os.path.join(_DATA_DIR, 'data.json')

CREATE_NO_WINDOW = 0x08000000
WIN_W, WIN_H     = 1100, 760
PORT_PREF        = 5757


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
        p = self.path.split('?')[0]
        if p in ('/', '/app.html'):
            html = get_html(self.server.server_address[1])
            self.send_response(200); self._cors()
            self.send_header('Content-Type', 'text/html; charset=utf-8')
            self.send_header('Content-Length', len(html))
            self.end_headers(); self.wfile.write(html)
        elif p == '/api/load':
            data = {}
            if os.path.exists(_DATA_PATH):
                try:
                    with open(_DATA_PATH, 'r', encoding='utf-8') as f:
                        data = json.load(f)
                except Exception: pass
            self._json(data)
        else:
            self.send_response(404); self.end_headers()

    def do_POST(self):
        n = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(n)
        if self.path == '/api/save':
            try:
                with open(_DATA_PATH, 'w', encoding='utf-8') as f:
                    json.dump(json.loads(body), f, indent=2, ensure_ascii=False)
                self._json({'ok': True})
            except Exception as e:
                self._json({'ok': False, 'error': str(e)}, 500)
        else:
            self.send_response(404); self.end_headers()

    def _json(self, data, status=200):
        body = json.dumps(data).encode('utf-8')
        self.send_response(status); self._cors()
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', len(body))
        self.end_headers(); self.wfile.write(body)

    def _cors(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')


def start_server():
    """
    Bind the port synchronously on the calling thread.
    Returns (server, port, is_new).
    If PORT_PREF is already taken, assume a previous instance is running.
    """
    for port in [PORT_PREF] + list(range(5758, 5800)):
        try:
            srv = http.server.HTTPServer(('127.0.0.1', port), FloHandler)
            return srv, port, True
        except OSError:
            if port == PORT_PREF:
                return None, port, False  # existing server
            continue
    raise RuntimeError('No free port found')


def wait_for_http(port, timeout=10.0):
    """
    Send a raw HTTP GET over a plain socket and wait for '200' in the
    response. This is the most reliable method inside a PyInstaller exe
    — no urllib, no ssl, no import side-effects.
    """
    import socket
    req = b'GET /app.html HTTP/1.0\r\nHost: 127.0.0.1\r\n\r\n'
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            s = socket.socket()
            s.settimeout(0.5)
            s.connect(('127.0.0.1', port))
            s.sendall(req)
            resp = s.recv(64).decode('utf-8', errors='ignore')
            s.close()
            if '200' in resp:
                return True
        except Exception:
            pass
        time.sleep(0.05)
    return False


def find_browser():
    lad  = os.environ.get('LOCALAPPDATA', '')
    pf   = os.environ.get('PROGRAMFILES',       r'C:\Program Files')
    pf86 = os.environ.get('PROGRAMFILES(X86)',  r'C:\Program Files (x86)')
    for path in [
        os.path.join(pf86, r'Microsoft\Edge\Application\msedge.exe'),
        os.path.join(pf,   r'Microsoft\Edge\Application\msedge.exe'),
        os.path.join(lad,  r'Microsoft\Edge\Application\msedge.exe'),
        os.path.join(pf,   r'Google\Chrome\Application\chrome.exe'),
        os.path.join(pf86, r'Google\Chrome\Application\chrome.exe'),
        os.path.join(lad,  r'Google\Chrome\Application\chrome.exe'),
        os.path.join(pf,   r'BraveSoftware\Brave-Browser\Application\brave.exe'),
        os.path.join(lad,  r'BraveSoftware\Brave-Browser\Application\brave.exe'),
    ]:
        if path and os.path.exists(path):
            return path
    return None


def launch_browser(url, browser_path):
    profile = os.path.join(_DATA_DIR, 'browser-profile')
    os.makedirs(profile, exist_ok=True)
    return subprocess.Popen(
        [browser_path, f'--app={url}', f'--window-size={WIN_W},{WIN_H}',
         f'--user-data-dir={profile}', '--no-first-run',
         '--no-default-browser-check', '--disable-extensions',
         '--disable-background-networking', '--disable-sync',
         '--disable-translate', '--hide-crash-restore-bubble'],
        creationflags=CREATE_NO_WINDOW,
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )


def main():
    srv, port, is_new = start_server()

    if not is_new:
        # A previous instance is already serving — just open a new window
        url = f'http://127.0.0.1:{port}/app.html'
        browser = find_browser()
        if browser:
            launch_browser(url, browser).wait()
        else:
            webbrowser.open(url)
        return

    # Port is bound (but serve_forever not started yet).
    # Launch browser in a background thread AFTER we confirm HTTP is ready.
    # serve_forever runs on the main thread — the OS guarantees it starts
    # accepting connections as soon as we call it, because the socket is
    # already bound and listen()ed by HTTPServer.__init__.
    url = f'http://127.0.0.1:{port}/app.html'

    def open_browser():
        # Wait for a real HTTP 200 before launching
        wait_for_http(port)
        browser = find_browser()
        if browser:
            launch_browser(url, browser)
        else:
            webbrowser.open(url)

    threading.Thread(target=open_browser, daemon=True).start()

    # This blocks forever (until the process is killed when Edge closes)
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == '__main__':
    main()
