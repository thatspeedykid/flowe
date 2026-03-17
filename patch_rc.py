import re, os
f = os.path.join('windows', 'runner', 'Runner.rc')
if not os.path.exists(f):
    exit(0)
txt = open(f, encoding='utf-8-sig').read()
txt = txt.replace('flowe.exe', 'Flowe.exe')
txt = re.sub(r'VALUE "FileDescription",\s*"[^"]*"',  'VALUE "FileDescription", "Flowe - Personal Finance Tracker"', txt)
txt = re.sub(r'VALUE "ProductName",\s*"[^"]*"',       'VALUE "ProductName", "Flowe"', txt)
txt = re.sub(r'VALUE "CompanyName",\s*"[^"]*"',       'VALUE "CompanyName", "PrivacyChase"', txt)
txt = re.sub(r'VALUE "LegalCopyright",\s*"[^"]*"',    'VALUE "LegalCopyright", "Copyright 2026 PrivacyChase. MIT License."', txt)
open(f, 'w', encoding='utf-8').write(txt)
print('  [OK] Runner.rc patched.')
