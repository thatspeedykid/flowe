# flo_linux.spec - PyInstaller build spec for Linux
block_cipher = None

a = Analysis(
    ['flo_linux.py'],
    pathex=['.'],
    binaries=[],
    datas=[('app.html', '.')],
    hiddenimports=[],
    hookspath=[],
    runtime_hooks=[],
    excludes=['pythonnet', 'webview', 'clr', 'tkinter'],
    cipher=block_cipher,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz, a.scripts, a.binaries, a.zipfiles, a.datas, [],
    name='flo', debug=False, strip=True, upx=True,
    console=False, runtime_tmpdir=None,
)
