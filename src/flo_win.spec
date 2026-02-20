# flo_win.spec - PyInstaller build spec for Windows
# Run: python -m PyInstaller flo_win.spec --noconfirm

block_cipher = None

a = Analysis(
    ['flo_win.py'],
    pathex=['.'],
    binaries=[],
    datas=[
        # app.html gets extracted to sys._MEIPASS at runtime
        ('app.html', '.'),
    ],
    hiddenimports=[],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=['pythonnet', 'webview', 'clr', 'tkinter'],
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name='flo',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,      # no CMD window
    icon='flo.ico',
)
