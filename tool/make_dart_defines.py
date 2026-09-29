import json
import re
from pathlib import Path

root = Path(__file__).resolve().parent.parent
db = (root / 'lib/config/database_config_local.dart').read_text(encoding='utf-8')


def grab(pat: str, text: str, default: str = '') -> str:
    m = re.search(pat, text)
    return m.group(1) if m else default


host = grab(r"dbHost = '([^']+)'", db)
port = grab(r'dbPort = (\d+)', db)
user = grab(r"dbUser = '([^']+)'", db)
password = grab(r"dbPassword = '([^']+)'", db)
name = grab(r"dbName = '([^']+)'", db)

gemini = ''
candidates = []
term = Path.home() / '.cursor/projects/c-Users-Rutuja-Dugaje-Desktop-Shravani-thermal/terminals'
search_roots = []
if term.exists():
    search_roots.append(term)
transcripts = Path.home() / '.cursor/projects/c-Users-Rutuja-Dugaje-Desktop-Shravani-thermal/agent-transcripts'
if transcripts.exists():
    search_roots.append(transcripts)

for root_dir in search_roots:
    for p in root_dir.rglob('*'):
        if p.suffix.lower() not in {'.txt', '.jsonl'}:
            continue
        try:
            t = p.read_text(encoding='utf-8', errors='ignore')
        except OSError:
            continue
        for m in re.finditer(r'GEMINI_API_KEY=([^\s"\\]+)', t):
            val = m.group(1).strip()
            if val and val not in {'.', '..', '...', 'YOUR_GEMINI_API_KEY'} and len(val) >= 20:
                candidates.append(val)

if candidates:
    # Prefer the longest plausible key token.
    gemini = max(candidates, key=len)

out = {
    'DB_HOST': host,
    'DB_PORT': port,
    'DB_USER': user,
    'DB_PASSWORD': password,
    'DB_NAME': name,
    'DB_SECURE': 'true',
    'GEMINI_API_KEY': gemini,
}

path = root / 'dart_defines.json'
path.write_text(json.dumps(out, indent=2), encoding='utf-8')
print('Wrote', path.name)
print(
    'HOST_SET', bool(host),
    'PORT', port,
    'USER_SET', bool(user),
    'PASS_SET', bool(password),
    'NAME', name,
    'GEMINI_SET', bool(gemini and gemini != 'YOUR_GEMINI_API_KEY'),
)

# Also pull Gemini from gitignored local Dart config if still missing.
if not gemini or gemini == 'YOUR_GEMINI_API_KEY':
    gemini_local = root / 'lib/config/gemini_config_local.dart'
    if gemini_local.exists():
        gt = gemini_local.read_text(encoding='utf-8')
        gm = re.search(r"apiKey = '([^']+)'", gt)
        if gm and gm.group(1) not in {'YOUR_GEMINI_API_KEY', '', '...'}:
            gemini = gm.group(1)
            out['GEMINI_API_KEY'] = gemini
            path.write_text(json.dumps(out, indent=2), encoding='utf-8')
            print('GEMINI_SET', True, '(from local config)')
